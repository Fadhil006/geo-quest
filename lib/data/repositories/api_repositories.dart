import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/spawn_location.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/api_service.dart';

// ═══════════════════════════════════════════════════
// API AUTH REPOSITORY — Google Sign-In → Backend JWT
// ═══════════════════════════════════════════════════
class ApiAuthRepository implements AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _api = ApiService();

  Team? _currentTeam;
  AppUser? _currentUser;
  final _teamController = StreamController<Team?>.broadcast();

  AppUser? get currentUser => _currentUser;

  /// Sign in with Google → send idToken to backend → get custom JWT
  Future<AppUser> signInWithGoogle() async {
    // 1. Trigger Google Sign-In
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    // 2. Get the Google ID token
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    // 3. Send idToken to backend → POST /api/auth/google
    final authResponse = await _api.post('/auth/google', body: {
      'idToken': idToken,
    }, auth: false);

    // 4. Store the custom JWT from backend
    final jwt = authResponse['token'] as String;
    final uid = authResponse['uid'] as String;
    final email = authResponse['email'] as String;
    _api.setAuth(jwt: jwt, uid: uid, email: email);

    // 5. Register/update user profile on backend
    try {
      final profileResponse = await _api.post('/users/register', body: {
        'displayName': googleUser.displayName ?? 'GeoQuest Player',
        'email': email,
        'photoUrl': googleUser.photoUrl,
      });
      _currentUser = _userFromJson(profileResponse);
    } catch (_) {
      // If register fails (user might already exist), build from auth response
      _currentUser = AppUser(
        uid: uid,
        email: email,
        displayName: googleUser.displayName ?? 'GeoQuest Player',
        photoUrl: googleUser.photoUrl,
        createdAt: DateTime.now(),
      );
    }

    return _currentUser!;
  }

  /// Check if we have a stored JWT (for auto-login)
  bool get isSignedIn => _api.isAuthenticated;

  /// Fetch user profile from backend
  Future<AppUser> getProfile() async {
    final response = await _api.get('/users/me');
    _currentUser = _userFromJson(response);
    return _currentUser!;
  }

  /// Sign out — clear JWT and Google session
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _api.clearAuth();
    _currentUser = null;
    _currentTeam = null;
    _teamController.add(null);
  }

  // ── Team operations ──

  /// Fetch all available teams (public endpoint)
  Future<List<Team>> getTeams() async {
    final response = await _api.get('/teams');
    return (response as List).map((json) => _teamFromJson(json)).toList();
  }

  /// Create a new team
  Future<Team> createTeam(String teamName) async {
    final response = await _api.post('/teams', body: {
      'teamName': teamName,
    });
    _currentTeam = _teamFromJson(response);
    _teamController.add(_currentTeam);
    return _currentTeam!;
  }

  /// Join an existing team by ID
  Future<Team> joinTeam(String teamId) async {
    final response = await _api.post('/teams/$teamId/join');
    _currentTeam = _teamFromJson(response);
    _teamController.add(_currentTeam);
    return _currentTeam!;
  }

  /// Leave a team
  Future<void> leaveTeam(String teamId) async {
    final uid = _api.uid;
    if (uid == null) return;
    await _api.delete('/teams/$teamId/members/$uid');
    _currentTeam = null;
    _teamController.add(null);
  }

  AppUser _userFromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String? ?? json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Team _teamFromJson(Map<String, dynamic> json) {
    return Team(
      id: (json['teamId'] ?? json['id'] ?? '').toString(),
      teamName: json['teamName'] as String? ?? '',
      members: List<String>.from(json['members'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      sessionId: json['sessionId'] as String?,
    );
  }

  // ── Legacy AuthRepository interface ──

  @override
  Future<Team> registerTeam({
    required String teamName,
    required List<String> members,
  }) async {
    return createTeam(teamName);
  }

  @override
  Future<Team> loginTeam(String teamId) async {
    return joinTeam(teamId);
  }

  @override
  Future<void> logout() => signOut();

  @override
  Stream<Team?> get currentTeamStream => _teamController.stream;

  @override
  Team? get currentTeam => _currentTeam;
}

// ═══════════════════════════════════════════════════
// API SESSION REPOSITORY
// ═══════════════════════════════════════════════════
class ApiSessionRepository implements SessionRepository {
  final ApiService _api = ApiService();
  Session? _activeSession;
  final _sessionController = StreamController<Session?>.broadcast();

  @override
  Future<Session> createSession(String teamId) async {
    final response = await _api.post('/sessions/start', body: {
      'teamId': teamId,
    });
    _activeSession = _sessionFromJson(response);
    _sessionController.add(_activeSession);
    return _activeSession!;
  }

  @override
  Future<Session?> getActiveSession(String teamId) async {
    return _activeSession;
  }

  @override
  Stream<Session?> sessionStream(String teamId) async* {
    yield _activeSession;
    await for (final session in _sessionController.stream) {
      yield session;
    }
  }

  @override
  Future<void> endSession(String sessionId) async {
    _activeSession = _activeSession?.copyWith(isActive: false);
    _sessionController.add(_activeSession);
  }

  @override
  Future<void> updateSession(Session session) async {
    _activeSession = session;
    _sessionController.add(_activeSession);
  }

  @override
  Future<void> checkAndEndExpiredSession(String sessionId) async {
    if (_activeSession != null && _activeSession!.isExpired) {
      await endSession(sessionId);
    }
  }

  /// Fetch remaining time from server
  Future<Map<String, dynamic>> getRemainingTime(String sessionId) async {
    final data = await _api.get('/sessions/$sessionId/remaining-time');
    return Map<String, dynamic>.from(data);
  }

  /// Fetch full session details from server
  Future<Session> getSessionDetails(String sessionId) async {
    final response = await _api.get('/sessions/$sessionId');
    _activeSession = _sessionFromJson(response);
    _sessionController.add(_activeSession);
    return _activeSession!;
  }

  Session _sessionFromJson(Map<String, dynamic> json) {
    return Session(
      id: (json['sessionId'] ?? json['id'] ?? '').toString(),
      teamId: (json['teamId'] ?? '').toString(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalAnswered: 0,
      correctAnswers: 0,
      currentDifficulty: ChallengeDifficulty.easy,
      completedChallengeIds:
          List<String>.from(json['answeredQuestionIds'] ?? []),
      skippedChallengeIds: [],
      isActive: json['status'] == 'active' || json['active'] == true,
    );
  }
}

// ═══════════════════════════════════════════════════
// API CHALLENGE REPOSITORY
// ═══════════════════════════════════════════════════
class ApiChallengeRepository implements ChallengeRepository {
  final ApiService _api = ApiService();
  final ApiSessionRepository _sessionRepo;

  /// Cached spawn locations
  List<SpawnLocation>? _spawnLocations;

  /// Set of question IDs already answered — prevents repetition
  final Set<String> _answeredQuestionIds = {};

  ApiChallengeRepository(this._sessionRepo);

  /// Unlock questions when user is near a spawn location.
  /// POST /api/questions/unlock { sessionId, userLat, userLng }
  /// Server checks Haversine distance — returns unlocked questions.
  Future<List<Map<String, dynamic>>> unlockQuestions({
    required String sessionId,
    required double userLat,
    required double userLng,
  }) async {
    final response = await _api.post('/questions/unlock', body: {
      'sessionId': sessionId,
      'userLat': userLat,
      'userLng': userLng,
    });
    final questions = List<Map<String, dynamic>>.from(response as List);
    // Track unlocked question IDs
    for (final q in questions) {
      if (q['questionId'] != null) {
        // Only track non-locked questions
        final isLocked = q['locked'] == true;
        if (!isLocked) {
          // Question is available — don't mark as answered yet
        }
      }
    }
    return questions;
  }

  /// Submit an answer with GPS coordinates.
  /// POST /api/answers/submit { sessionId, questionId, answer, spawnLocationId, userLat, userLng }
  Future<Map<String, dynamic>> submitAnswerToApi({
    required String sessionId,
    required String questionId,
    required String answer,
    required String spawnLocationId,
    required double userLat,
    required double userLng,
  }) async {
    final response = await _api.post('/answers/submit', body: {
      'sessionId': sessionId,
      'questionId': questionId,
      'answer': answer,
      'spawnLocationId': spawnLocationId,
      'userLat': userLat,
      'userLng': userLng,
    });
    final result = Map<String, dynamic>.from(response);

    // Mark as answered to prevent repetition
    _answeredQuestionIds.add(questionId);

    // Update session score locally
    final session = await _sessionRepo.getActiveSession('');
    if (session != null) {
      final isCorrect = result['correct'] == true;
      final updated = session.copyWith(
        score: (result['totalScore'] as num?)?.toInt() ?? session.score,
        completedChallengeIds: [
          ...session.completedChallengeIds,
          if (isCorrect) questionId,
        ],
        totalAnswered: session.totalAnswered + 1,
        correctAnswers: session.correctAnswers + (isCorrect ? 1 : 0),
      );
      await _sessionRepo.updateSession(updated);
    }

    return result;
  }

  /// Check if a question was already answered in this session
  bool isQuestionAnswered(String questionId) {
    return _answeredQuestionIds.contains(questionId);
  }

  /// Clear tracking on new session
  void clearSession() {
    _answeredQuestionIds.clear();
    _spawnLocations = null;
  }

  // ── Legacy ChallengeRepository interface ──

  @override
  Future<List<Challenge>> getChallenges() async {
    return [];
  }

  @override
  Future<List<Challenge>> getChallengesByDifficulty(
      ChallengeDifficulty difficulty) async {
    return [];
  }

  @override
  Future<Challenge> getChallengeById(String challengeId) async {
    final response = await _api.get('/questions/$challengeId');
    return _challengeFromJson(response);
  }

  @override
  Future<SubmissionResult> submitAnswer({
    required String sessionId,
    required String challengeId,
    required String answer,
  }) async {
    // Requires GPS coords — use submitAnswerToApi() for full flow
    throw UnimplementedError(
        'Use submitAnswerToApi() with GPS coordinates instead');
  }

  @override
  Future<int> skipChallenge({
    required String sessionId,
    required String challengeId,
  }) async {
    return 0;
  }

  @override
  Future<List<Challenge>> getAvailableChallenges({
    required String sessionId,
    required ChallengeDifficulty difficulty,
  }) async {
    return [];
  }

  Challenge _challengeFromJson(Map<String, dynamic> json) {
    return Challenge(
      id: (json['questionId'] ?? json['id'] ?? '').toString(),
      title: json['title'] as String? ?? json['text'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: ChallengeCategory.logicalReasoning,
      difficulty: _parseDifficulty(json['difficulty']),
      type: json['options'] != null
          ? ChallengeType.multipleChoice
          : ChallengeType.textInput,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 10,
      question: json['title'] as String? ?? json['text'] as String? ?? '',
      options:
          json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }

  ChallengeDifficulty _parseDifficulty(dynamic value) {
    if (value == null) return ChallengeDifficulty.easy;
    final d = value is int ? value : int.tryParse(value.toString()) ?? 1;
    switch (d) {
      case 1:
        return ChallengeDifficulty.easy;
      case 2:
        return ChallengeDifficulty.medium;
      case 3:
        return ChallengeDifficulty.hard;
      default:
        return ChallengeDifficulty.easy;
    }
  }
}

// ═══════════════════════════════════════════════════
// API LEADERBOARD REPOSITORY
// ═══════════════════════════════════════════════════
class ApiLeaderboardRepository implements LeaderboardRepository {
  final ApiService _api = ApiService();
  final _controller = StreamController<List<LeaderboardEntry>>.broadcast();
  Timer? _pollTimer;

  /// Start polling the leaderboard every 30 seconds
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAndEmit();
    });
    _fetchAndEmit();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchAndEmit() async {
    try {
      final entries = await getLeaderboard();
      _controller.add(entries);
    } catch (_) {}
  }

  @override
  Stream<List<LeaderboardEntry>> get leaderboardStream async* {
    yield await getLeaderboard();
    await for (final entries in _controller.stream) {
      yield entries;
    }
  }

  @override
  Future<void> updateScore({
    required String teamId,
    required String teamName,
    required int score,
    required int completedCount,
  }) async {
    // Score updates happen server-side on answer submission
    await _fetchAndEmit();
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await _api.get('/leaderboard', auth: false);
    final entries = (response as List).asMap().entries.map((e) {
      final json = e.value;
      return LeaderboardEntry(
        teamId: (json['teamId'] ?? '').toString(),
        teamName: json['teamName'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
        rank: e.key + 1,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : DateTime.now(),
      );
    }).toList();
    return entries;
  }
}
