import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_config.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/repositories/api_repositories.dart';
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
final _mockChallengeRepo =
    MockChallengeRepository(_mockSessionRepo, _mockAuthRepo);
final _mockLeaderboardRepo = MockLeaderboardRepository();

// ══════════════════════════════════════════════
// API SINGLETONS (for online mode)
// ══════════════════════════════════════════════
final _apiAuthRepo = ApiAuthRepository();
final _apiSessionRepo = ApiSessionRepository();
final _apiChallengeRepo = ApiChallengeRepository(_apiSessionRepo);
final _apiLeaderboardRepo = ApiLeaderboardRepository();

/// ── Repository Providers ──
/// offlineMode → Mock repositories
/// online mode → API repositories connected to Spring Boot backend

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.offlineMode) return _mockAuthRepo;
  return _apiAuthRepo;
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (AppConfig.offlineMode) return _mockSessionRepo;
  return _apiSessionRepo;
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  if (AppConfig.offlineMode) return _mockChallengeRepo;
  return _apiChallengeRepo;
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  if (AppConfig.offlineMode) return _mockLeaderboardRepo;
  return _apiLeaderboardRepo;
});

/// ── API-specific providers ──

final apiAuthRepoProvider = Provider<ApiAuthRepository>((ref) => _apiAuthRepo);
final apiSessionRepoProvider = Provider<ApiSessionRepository>((ref) => _apiSessionRepo);
final apiChallengeRepoProvider = Provider<ApiChallengeRepository>((ref) => _apiChallengeRepo);
final apiLeaderboardRepoProvider = Provider<ApiLeaderboardRepository>((ref) => _apiLeaderboardRepo);

/// ── Use Case Providers ──

final startSessionUseCaseProvider = Provider<StartSessionUseCase>(
  (ref) => StartSessionUseCase(ref.read(sessionRepositoryProvider)),
);

final difficultyEngineProvider = Provider<DifficultyEngineUseCase>(
  (ref) => DifficultyEngineUseCase(),
);
