import '../entities/challenge.dart';

/// Use case: Progressive Difficulty Engine
/// Determines the next difficulty level based on performance metrics
class DifficultyEngineUseCase {
  // ── Difficulty Thresholds ──
  static const Map<ChallengeDifficulty, _DifficultyRange> _thresholds = {
    ChallengeDifficulty.easy: _DifficultyRange(minScore: 0, maxScore: 50),
    ChallengeDifficulty.medium: _DifficultyRange(minScore: 50, maxScore: 150),
    ChallengeDifficulty.hard: _DifficultyRange(minScore: 150, maxScore: 300),
    ChallengeDifficulty.expert: _DifficultyRange(minScore: 300, maxScore: 999999),
  };

  /// Calculate the appropriate difficulty level
  ChallengeDifficulty calculateDifficulty({
    required int currentScore,
    required double accuracyRate,
    required double averageSolveTimeSeconds,
    required int totalAnswered,
  }) {
    // Base difficulty from score
    var baseDifficulty = _getDifficultyFromScore(currentScore);

    // Accuracy boost: if accuracy > 80%, consider bumping up
    if (accuracyRate > 0.8 && totalAnswered >= 3) {
      baseDifficulty = _bumpUp(baseDifficulty);
    }

    // Speed boost: if solving faster than 60s average, consider bumping up
    if (averageSolveTimeSeconds < 60 && totalAnswered >= 3) {
      baseDifficulty = _bumpUp(baseDifficulty);
    }

    // Accuracy penalty: if accuracy < 40%, consider bumping down
    if (accuracyRate < 0.4 && totalAnswered >= 3) {
      baseDifficulty = _bumpDown(baseDifficulty);
    }

    return baseDifficulty;
  }

  /// Get base difficulty from score thresholds
  ChallengeDifficulty _getDifficultyFromScore(int score) {
    for (final entry in _thresholds.entries) {
      if (score >= entry.value.minScore && score < entry.value.maxScore) {
        return entry.key;
      }
    }
    return ChallengeDifficulty.expert;
  }

  /// Calculate points for a challenge based on difficulty and speed
  int calculatePoints({
    required ChallengeDifficulty difficulty,
    required int timeLimitSeconds,
    required int solveTimeSeconds,
  }) {
    final basePoints = _basePointsForDifficulty(difficulty);

    // Time bonus: faster solving = more points (up to 50% bonus)
    final timeRatio = 1 - (solveTimeSeconds / timeLimitSeconds).clamp(0.0, 1.0);
    final timeBonus = (basePoints * 0.5 * timeRatio).round();

    return basePoints + timeBonus;
  }

  /// Skip penalty amount
  int skipPenalty(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 5;
      case ChallengeDifficulty.medium:
        return 10;
      case ChallengeDifficulty.hard:
        return 15;
      case ChallengeDifficulty.expert:
        return 20;
    }
  }

  int _basePointsForDifficulty(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 10;
      case ChallengeDifficulty.medium:
        return 25;
      case ChallengeDifficulty.hard:
        return 50;
      case ChallengeDifficulty.expert:
        return 100;
    }
  }

  ChallengeDifficulty _bumpUp(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy:
        return ChallengeDifficulty.medium;
      case ChallengeDifficulty.medium:
        return ChallengeDifficulty.hard;
      case ChallengeDifficulty.hard:
        return ChallengeDifficulty.expert;
      case ChallengeDifficulty.expert:
        return ChallengeDifficulty.expert;
    }
  }

  ChallengeDifficulty _bumpDown(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy:
        return ChallengeDifficulty.easy;
      case ChallengeDifficulty.medium:
        return ChallengeDifficulty.easy;
      case ChallengeDifficulty.hard:
        return ChallengeDifficulty.medium;
      case ChallengeDifficulty.expert:
        return ChallengeDifficulty.hard;
    }
  }
}

class _DifficultyRange {
  final int minScore;
  final int maxScore;

  const _DifficultyRange({required this.minScore, required this.maxScore});
}

