import 'challenge.dart';

/// GeoQuest — Game Session Entity
/// Represents a team's active 2-hour quest session
class Session {
  final String id;
  final String teamId;
  final DateTime startTime;
  final DateTime endTime;
  final int score;
  final int totalAnswered;
  final int correctAnswers;
  final ChallengeDifficulty currentDifficulty;
  final List<String> completedChallengeIds;
  final List<String> skippedChallengeIds;
  final bool isActive;
  final String? activeChallengeId;

  const Session({
    required this.id,
    required this.teamId,
    required this.startTime,
    required this.endTime,
    this.score = 0,
    this.totalAnswered = 0,
    this.correctAnswers = 0,
    this.currentDifficulty = ChallengeDifficulty.easy,
    this.completedChallengeIds = const [],
    this.skippedChallengeIds = const [],
    this.isActive = true,
    this.activeChallengeId,
  });

  /// Derived properties
  double get accuracyRate =>
      totalAnswered > 0 ? correctAnswers / totalAnswered : 0.0;

  Duration get remainingTime => endTime.difference(DateTime.now());

  bool get isExpired => DateTime.now().isAfter(endTime);

  int get challengesCompleted => completedChallengeIds.length;

  Session copyWith({
    String? id,
    String? teamId,
    DateTime? startTime,
    DateTime? endTime,
    int? score,
    int? totalAnswered,
    int? correctAnswers,
    ChallengeDifficulty? currentDifficulty,
    List<String>? completedChallengeIds,
    List<String>? skippedChallengeIds,
    bool? isActive,
    String? activeChallengeId,
  }) {
    return Session(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      score: score ?? this.score,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      completedChallengeIds:
          completedChallengeIds ?? this.completedChallengeIds,
      skippedChallengeIds: skippedChallengeIds ?? this.skippedChallengeIds,
      isActive: isActive ?? this.isActive,
      activeChallengeId: activeChallengeId ?? this.activeChallengeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Session && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

