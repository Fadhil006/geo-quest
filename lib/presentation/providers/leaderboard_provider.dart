import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import 'service_providers.dart';

/// Real-time leaderboard stream provider
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final repo = ref.read(leaderboardRepositoryProvider);
  return repo.leaderboardStream;
});

/// Leaderboard updater — call after every answer to keep board in sync
class LeaderboardUpdater extends StateNotifier<void> {
  final LeaderboardRepository _repo;
  LeaderboardUpdater(this._repo) : super(null);

  Future<void> updateScore({
    required String teamId,
    required String teamName,
    required int score,
    required int completedCount,
  }) async {
    await _repo.updateScore(
      teamId: teamId,
      teamName: teamName,
      score: score,
      completedCount: completedCount,
    );
  }
}

final leaderboardUpdaterProvider =
    StateNotifierProvider<LeaderboardUpdater, void>((ref) {
  return LeaderboardUpdater(ref.read(leaderboardRepositoryProvider));
});
