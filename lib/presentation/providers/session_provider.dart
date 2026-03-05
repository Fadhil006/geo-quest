import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

/// Session state notifier
class SessionNotifier extends StateNotifier<AsyncValue<Session?>> {
  final SessionRepository _sessionRepository;
  final String? _teamId;

  SessionNotifier(this._sessionRepository, this._teamId)
      : super(const AsyncValue.loading()) {
    if (_teamId != null) {
      _loadSession();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadSession() async {
    try {
      final session = await _sessionRepository.getActiveSession(_teamId!);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSession() async {
    if (_teamId == null) return;
    state = const AsyncValue.loading();
    try {
      final session = await _sessionRepository.createSession(_teamId);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession() async {
    final session = state.valueOrNull;
    if (session == null) return;
    try {
      await _sessionRepository.endSession(session.id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshSession() async {
    if (_teamId != null) await _loadSession();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<Session?>>((ref) {
  final team = ref.watch(currentTeamProvider);
  return SessionNotifier(
    ref.read(sessionRepositoryProvider),
    team?.id,
  );
});

/// Stream-based session provider for real-time updates
final sessionStreamProvider = StreamProvider<Session?>((ref) {
  final team = ref.watch(currentTeamProvider);
  if (team == null) return Stream.value(null);
  return ref.read(sessionRepositoryProvider).sessionStream(team.id);
});

