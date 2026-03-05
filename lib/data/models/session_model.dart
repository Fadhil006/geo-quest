import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/session.dart';

/// Firestore data model for Session
class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.teamId,
    required super.startTime,
    required super.endTime,
    super.score,
    super.totalAnswered,
    super.correctAnswers,
    super.currentDifficulty,
    super.completedChallengeIds,
    super.skippedChallengeIds,
    super.isActive,
    super.activeChallengeId,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 2)),
      score: data['score'] ?? 0,
      totalAnswered: data['totalAnswered'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      currentDifficulty: _difficultyFromString(data['currentDifficulty']),
      completedChallengeIds:
          List<String>.from(data['completedChallengeIds'] ?? []),
      skippedChallengeIds:
          List<String>.from(data['skippedChallengeIds'] ?? []),
      isActive: data['isActive'] ?? true,
      activeChallengeId: data['activeChallengeId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'score': score,
      'totalAnswered': totalAnswered,
      'correctAnswers': correctAnswers,
      'currentDifficulty': currentDifficulty.name,
      'completedChallengeIds': completedChallengeIds,
      'skippedChallengeIds': skippedChallengeIds,
      'isActive': isActive,
      'activeChallengeId': activeChallengeId,
    };
  }

  factory SessionModel.fromEntity(Session session) {
    return SessionModel(
      id: session.id,
      teamId: session.teamId,
      startTime: session.startTime,
      endTime: session.endTime,
      score: session.score,
      totalAnswered: session.totalAnswered,
      correctAnswers: session.correctAnswers,
      currentDifficulty: session.currentDifficulty,
      completedChallengeIds: session.completedChallengeIds,
      skippedChallengeIds: session.skippedChallengeIds,
      isActive: session.isActive,
      activeChallengeId: session.activeChallengeId,
    );
  }

  static ChallengeDifficulty _difficultyFromString(String? value) {
    return ChallengeDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChallengeDifficulty.easy,
    );
  }
}

