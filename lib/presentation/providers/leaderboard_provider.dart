import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import 'service_providers.dart';

/// Real-time leaderboard stream provider
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final repo = ref.read(leaderboardRepositoryProvider);
  return repo.leaderboardStream;
});

