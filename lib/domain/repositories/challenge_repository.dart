import '../entities/challenge.dart';

/// Abstract challenge repository contract
abstract class ChallengeRepository {
  /// Get all active challenges
  Future<List<Challenge>> getChallenges();

  /// Get challenges filtered by difficulty
  Future<List<Challenge>> getChallengesByDifficulty(ChallengeDifficulty difficulty);

  /// Get a single challenge by ID
  Future<Challenge> getChallengeById(String challengeId);

  /// Submit an answer for validation (server-side)
  /// Returns true if correct, with points awarded
  Future<SubmissionResult> submitAnswer({
    required String sessionId,
    required String challengeId,
    required String answer,
  });

  /// Skip a challenge (with penalty)
  Future<int> skipChallenge({
    required String sessionId,
    required String challengeId,
  });

  /// Get challenges not yet completed by the session
  Future<List<Challenge>> getAvailableChallenges({
    required String sessionId,
    required ChallengeDifficulty difficulty,
  });
}

/// Result of a challenge submission
class SubmissionResult {
  final bool isCorrect;
  final int pointsAwarded;
  final int newTotalScore;
  final String? feedback;

  const SubmissionResult({
    required this.isCorrect,
    required this.pointsAwarded,
    required this.newTotalScore,
    this.feedback,
  });
}

