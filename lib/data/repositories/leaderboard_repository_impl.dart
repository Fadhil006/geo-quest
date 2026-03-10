import '../../core/constants/firebase_paths.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/realtime_db_datasource.dart';
import '../models/leaderboard_entry_model.dart';

/// Firebase Realtime DB implementation of LeaderboardRepository
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final RealtimeDbDatasource _realtimeDb;

  LeaderboardRepositoryImpl(this._realtimeDb);

  @override
  Stream<List<LeaderboardEntry>> get leaderboardStream {
    return _realtimeDb
        .streamOrdered(
          FirebasePaths.leaderboard,
          orderByChild: 'score',
        )
        .map((event) {
      final snapshot = event.snapshot;
      final data = snapshot.value;
      if (data == null) return <LeaderboardEntry>[];

      final map = Map<String, dynamic>.from(data as Map);
      final entries = map.entries.map((e) {
        return LeaderboardEntryModel.fromRealtimeDb(
          e.key,
          Map<dynamic, dynamic>.from(e.value),
        );
      }).toList();

      // Sort by score descending
      entries.sort((a, b) => b.score.compareTo(a.score));

      // Assign ranks
      return entries.asMap().entries.map((e) {
        return e.value.copyWith(rank: e.key + 1);
      }).toList();
    });
  }

  @override
  Future<void> updateScore({
    required String teamId,
    required String teamName,
    required int score,
    required int completedCount,
  }) async {
    final entry = LeaderboardEntryModel(
      teamId: teamId,
      teamName: teamName,
      score: score,
      completedCount: completedCount,
      rank: 0, // Will be calculated by stream
      lastUpdated: DateTime.now(),
    );

    await _realtimeDb.setData(
      '${FirebasePaths.leaderboard}/$teamId',
      entry.toRealtimeDb(),
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    // Use stream to get a single snapshot
    final entries = <LeaderboardEntry>[];
    await for (final list in leaderboardStream) {
      entries.addAll(list);
      break;
    }
    return entries;
  }
}

