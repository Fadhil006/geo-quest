import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/auth_repository.dart';
import 'service_providers.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final Team? team;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.team,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, Team? team, String? error}) {
    return AuthState(
      status: status ?? this.status,
      team: team ?? this.team,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState());

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

