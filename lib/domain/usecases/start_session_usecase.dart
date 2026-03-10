import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Use case: Start a new 2-hour quest session
class StartSessionUseCase {
  final SessionRepository _sessionRepository;

  StartSessionUseCase(this._sessionRepository);

  /// Creates a server-timestamped session with exactly 2h duration
  /// Returns existing active session if one exists
  Future<Session> execute(String teamId) async {
    // Check for existing active session
    final existing = await _sessionRepository.getActiveSession(teamId);
    if (existing != null && !existing.isExpired) {
      return existing;
    }

    // End any expired session
    if (existing != null && existing.isExpired) {
      await _sessionRepository.endSession(existing.id);
    }

    // Create new session
    return _sessionRepository.createSession(teamId);
  }
}

