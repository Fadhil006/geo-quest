import '../../domain/entities/team.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/team_model.dart';

/// Firebase implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _authDatasource;

  Team? _cachedTeam;
  String? _currentTeamId;

  AuthRepositoryImpl(this._authDatasource);

  @override
  Future<Team> registerTeam({
    required String teamName,
    required List<String> members,
  }) async {
    final team = await _authDatasource.registerTeam(
      teamName: teamName,
      members: members,
    );
    _cachedTeam = team;
    _currentTeamId = team.id;
    return team;
  }

  @override
  Future<Team> loginTeam(String teamId) async {
    final team = await _authDatasource.loginTeam(teamId);
    _cachedTeam = team;
    _currentTeamId = team.id;
    return team;
  }

  @override
  Future<void> logout() async {
    _cachedTeam = null;
    _currentTeamId = null;
    await _authDatasource.logout();
  }

  @override
  Stream<Team?> get currentTeamStream {
    final userId = _currentTeamId ?? _authDatasource.currentUserId;
    if (userId == null) return Stream.value(null);
    return _authDatasource.teamStream(userId).map((team) {
      _cachedTeam = team;
      return team;
    });
  }

  @override
  Team? get currentTeam => _cachedTeam;
}

