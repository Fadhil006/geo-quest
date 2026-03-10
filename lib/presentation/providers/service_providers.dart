import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/usecases/difficulty_engine_usecase.dart';
import '../../domain/usecases/start_session_usecase.dart';

// ══════════════════════════════════════════════
// MOCK SINGLETONS (shared so state persists)
// ══════════════════════════════════════════════
final _mockSessionRepo = MockSessionRepository();
final _mockAuthRepo = MockAuthRepository();
final _mockChallengeRepo = MockChallengeRepository(_mockSessionRepo);
final _mockLeaderboardRepo = MockLeaderboardRepository();

/// ── Repository Providers ──
/// In offline mode → Mock repositories (no Firebase needed)
/// In online mode → you must uncomment the Firebase imports below and
///   replace the mock returns with real implementations.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Online mode: return AuthRepositoryImpl(ref.read(firebaseAuthDatasourceProvider));
  return _mockAuthRepo;
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  // Online mode: return SessionRepositoryImpl(firestoreDs, realtimeDs);
  return _mockSessionRepo;
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  // Online mode: return ChallengeRepositoryImpl(firestoreDs);
  return _mockChallengeRepo;
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  // Online mode: return LeaderboardRepositoryImpl(realtimeDs);
  return _mockLeaderboardRepo;
});

/// ── Use Case Providers ──

final startSessionUseCaseProvider = Provider<StartSessionUseCase>(
  (ref) => StartSessionUseCase(ref.read(sessionRepositoryProvider)),
);

final difficultyEngineProvider = Provider<DifficultyEngineUseCase>(
  (ref) => DifficultyEngineUseCase(),
);
