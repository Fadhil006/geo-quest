import '../entities/leaderboard_entry.dart';

/// Abstract leaderboard repository contract
abstract class LeaderboardRepository {
  /// Stream of real-time leaderboard updates
  Stream<List<LeaderboardEntry>> get leaderboardStream;

  /// Update a team's score on the leaderboard
  Future<void> updateScore({
    required String teamId,
    required String teamName,
    required int score,
    required int completedCount,
  });

  /// Get current leaderboard snapshot
  Future<List<LeaderboardEntry>> getLeaderboard();
}

