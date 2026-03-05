import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_paths.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/firestore_datasource.dart';
import '../models/challenge_model.dart';

/// Firebase implementation of ChallengeRepository
class ChallengeRepositoryImpl implements ChallengeRepository {
  final FirestoreDatasource _firestore;

  ChallengeRepositoryImpl(this._firestore);

  @override
  Future<List<Challenge>> getChallenges() async {
    final snapshot = await _firestore
        .collection(FirebasePaths.challenges)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ChallengeModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<Challenge>> getChallengesByDifficulty(
      ChallengeDifficulty difficulty) async {
    final snapshot = await _firestore
        .collection(FirebasePaths.challenges)
        .where('isActive', isEqualTo: true)
        .where('difficulty', isEqualTo: difficulty.name)
        .get();

    return snapshot.docs
        .map((doc) => ChallengeModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<Challenge> getChallengeById(String challengeId) async {
    final doc = await _firestore.getDoc(FirebasePaths.challenges, challengeId);
    if (!doc.exists) {
      throw Exception('Challenge not found: $challengeId');
    }
    return ChallengeModel.fromFirestore(doc);
  }

  @override
  Future<SubmissionResult> submitAnswer({
    required String sessionId,
    required String challengeId,
    required String answer,
  }) async {
    // Server-side validation: write submission and let Cloud Function validate
    // For now, we write to a submissions collection and read the result
    final submissionRef = _firestore
        .collection(FirebasePaths.submissions)
        .doc();

    await submissionRef.set({
      'sessionId': sessionId,
      'challengeId': challengeId,
      'answer': answer.trim().toLowerCase(),
      'submittedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Wait for server validation (Cloud Function trigger)
    // Poll for result with timeout
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await submissionRef.get();
      final data = result.data();
      if (data != null && data['status'] != 'pending') {
        return SubmissionResult(
          isCorrect: data['isCorrect'] ?? false,
          pointsAwarded: data['pointsAwarded'] ?? 0,
          newTotalScore: data['newTotalScore'] ?? 0,
          feedback: data['feedback'],
        );
      }
    }

    // Timeout — fallback to client-side comparison (NOT recommended for production)
    throw Exception('Submission validation timed out. Please try again.');
  }

  @override
  Future<int> skipChallenge({
    required String sessionId,
    required String challengeId,
  }) async {
    // Record skip in session
    final sessionRef =
        _firestore.collection(FirebasePaths.sessions).doc(sessionId);

    await _firestore.instance.runTransaction((txn) async {
      final sessionDoc = await txn.get(sessionRef);
      final data = sessionDoc.data()!;
      final skipped = List<String>.from(data['skippedChallengeIds'] ?? []);
      final score = (data['score'] ?? 0) as int;

      skipped.add(challengeId);
      final penalty = 10; // configurable
      final newScore = (score - penalty).clamp(0, 999999);

      txn.update(sessionRef, {
        'skippedChallengeIds': skipped,
        'score': newScore,
        'activeChallengeId': null,
      });

      return newScore;
    });

    return 0; // Will be updated by transaction
  }

  @override
  Future<List<Challenge>> getAvailableChallenges({
    required String sessionId,
    required ChallengeDifficulty difficulty,
  }) async {
    // Get session to find completed/skipped challenges
    final sessionDoc =
        await _firestore.getDoc(FirebasePaths.sessions, sessionId);
    final sessionData = sessionDoc.data();
    final completed =
        List<String>.from(sessionData?['completedChallengeIds'] ?? []);
    final skipped =
        List<String>.from(sessionData?['skippedChallengeIds'] ?? []);
    final excluded = {...completed, ...skipped};

    // Get challenges of the target difficulty
    final challenges = await getChallengesByDifficulty(difficulty);

    // Filter out completed/skipped
    return challenges.where((c) => !excluded.contains(c.id)).toList();
  }
}

