import '../entities/team.dart';

/// Abstract auth repository contract
abstract class AuthRepository {
  /// Register a new team with members
  Future<Team> registerTeam({
    required String teamName,
    required List<String> members,
  });

  /// Login with existing team ID
  Future<Team> loginTeam(String teamId);

  /// Logout current team
  Future<void> logout();

  /// Stream of current authenticated team
  Stream<Team?> get currentTeamStream;

  /// Get current team synchronously (cached)
  Team? get currentTeam;
}

