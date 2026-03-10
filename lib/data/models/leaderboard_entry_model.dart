import '../../domain/entities/leaderboard_entry.dart';

/// Realtime Database data model for LeaderboardEntry
class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.teamId,
    required super.teamName,
    required super.score,
    required super.completedCount,
    required super.rank,
    super.isActive,
    required super.lastUpdated,
  });

  factory LeaderboardEntryModel.fromRealtimeDb(
      String key, Map<dynamic, dynamic> data) {
    return LeaderboardEntryModel(
      teamId: key,
      teamName: data['teamName'] ?? '',
      score: data['score'] ?? 0,
      completedCount: data['completedCount'] ?? 0,
      rank: data['rank'] ?? 0,
      isActive: data['isActive'] ?? true,
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toRealtimeDb() {
    return {
      'teamName': teamName,
      'score': score,
      'completedCount': completedCount,
      'rank': rank,
      'isActive': isActive,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory LeaderboardEntryModel.fromEntity(LeaderboardEntry entry) {
    return LeaderboardEntryModel(
      teamId: entry.teamId,
      teamName: entry.teamName,
      score: entry.score,
      completedCount: entry.completedCount,
      rank: entry.rank,
      isActive: entry.isActive,
      lastUpdated: entry.lastUpdated,
    );
  }
}

