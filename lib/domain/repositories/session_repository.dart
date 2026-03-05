import '../entities/session.dart';

/// Abstract session repository contract
abstract class SessionRepository {
  /// Create and start a new session for a team
  Future<Session> createSession(String teamId);

  /// Get the active session for a team
  Future<Session?> getActiveSession(String teamId);

  /// Stream of session updates (real-time)
  Stream<Session?> sessionStream(String teamId);

  /// End a session (lock score)
  Future<void> endSession(String sessionId);

  /// Update session data
  Future<void> updateSession(Session session);

  /// Check and auto-end expired sessions
  Future<void> checkAndEndExpiredSession(String sessionId);
}

