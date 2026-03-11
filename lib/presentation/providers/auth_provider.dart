import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_config.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/datasources/api_service.dart';
import 'service_providers.dart';

/// Auth state — tracks user + team separately
enum AuthStatus { initial, loading, authenticated, needsTeam, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final Team? team;
  final AppUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.team,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, Team? team, AppUser? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      team: team ?? this.team,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    // Check if user is already signed in on startup (JWT stored in ApiService)
    if (!AppConfig.offlineMode) {
      _checkExistingAuth();
    }
  }

  ApiAuthRepository? get _apiAuth =>
      _authRepository is ApiAuthRepository ? _authRepository : null;

  /// Check if JWT already exists (auto-login)
  Future<void> _checkExistingAuth() async {
    final api = ApiService();
    if (api.isAuthenticated && _apiAuth != null) {
      state = state.copyWith(status: AuthStatus.loading);
      try {
        final user = await _apiAuth!.getProfile();
        state = AuthState(
          status: AuthStatus.needsTeam,
          user: user,
        );
      } catch (_) {
        // Token expired or user not registered — send to login
        api.clearAuth();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  /// Google Sign-In → backend JWT flow
  Future<void> signInWithGoogle() async {
    if (AppConfig.offlineMode || _apiAuth == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _apiAuth!.signInWithGoogle();
      state = AuthState(
        status: AuthStatus.needsTeam,
        user: user,
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
    }
  }

  /// Create a new team
  Future<void> createTeam(String teamName) async {
    if (AppConfig.offlineMode || _apiAuth == null) return;
    try {
      final team = await _apiAuth!.createTeam(teamName);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        team: team,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Join an existing team
  Future<void> joinTeam(String teamId) async {
    if (AppConfig.offlineMode || _apiAuth == null) return;
    try {
      final team = await _apiAuth!.joinTeam(teamId);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        team: team,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get all available teams
  Future<List<Team>> getTeams() async {
    if (AppConfig.offlineMode || _apiAuth == null) return [];
    return _apiAuth!.getTeams();
  }

  // ── Legacy methods for offline mode ──

  Future<void> registerTeam({
    required String teamName,
    required List<String> members,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final team = await _authRepository.registerTeam(
        teamName: teamName,
        members: members,
      );
      state = AuthState(status: AuthStatus.authenticated, team: team);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> loginTeam(String teamId) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final team = await _authRepository.loginTeam(teamId);
      state = AuthState(status: AuthStatus.authenticated, team: team);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void setTeam(Team team) {
    state = AuthState(status: AuthStatus.authenticated, team: team);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

/// Convenience provider for current team
final currentTeamProvider = Provider<Team?>((ref) {
  return ref.watch(authProvider).team;
});

/// Convenience provider for current user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});
