/// GeoQuest — Leaderboard Entry Entity
class LeaderboardEntry {
  final String teamId;
  final String teamName;
  final int score;
  final int completedCount;
  final int rank;
  final bool isActive;
  final DateTime lastUpdated;

  const LeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.score,
    required this.completedCount,
    required this.rank,
    this.isActive = true,
    required this.lastUpdated,
  });

  LeaderboardEntry copyWith({
    String? teamId,
    String? teamName,
    int? score,
    int? completedCount,
    int? rank,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return LeaderboardEntry(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      score: score ?? this.score,
      completedCount: completedCount ?? this.completedCount,
      rank: rank ?? this.rank,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry && teamId == other.teamId;

  @override
  int get hashCode => teamId.hashCode;
}

