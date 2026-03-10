import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../core/constants/app_config.dart';
import '../datasources/question_loader.dart';

const _uuid = Uuid();

// ═══════════════════════════════════════════════════
// MOCK AUTH REPOSITORY
// ═══════════════════════════════════════════════════
class MockAuthRepository implements AuthRepository {
  Team? _currentTeam;
  final _teamController = StreamController<Team?>.broadcast();

  @override
  Future<Team> registerTeam({
    required String teamName,
    required List<String> members,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network
    _currentTeam = Team(
      id: _uuid.v4().substring(0, 8).toUpperCase(),
      teamName: teamName,
      members: members,
      createdAt: DateTime.now(),
    );
    _teamController.add(_currentTeam);
    return _currentTeam!;
  }

  @override
  Future<Team> loginTeam(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Accept any team ID in offline mode
    _currentTeam = Team(
      id: teamId,
      teamName: 'Team $teamId',
      members: ['Member 1', 'Member 2', 'Member 3'],
      createdAt: DateTime.now(),
    );
    _teamController.add(_currentTeam);
    return _currentTeam!;
  }

  @override
  Future<void> logout() async {
    _currentTeam = null;
    _teamController.add(null);
  }

  @override
  Stream<Team?> get currentTeamStream => _teamController.stream;

  @override
  Team? get currentTeam => _currentTeam;
}

// ═══════════════════════════════════════════════════
// MOCK SESSION REPOSITORY
// ═══════════════════════════════════════════════════
class MockSessionRepository implements SessionRepository {
  Session? _activeSession;
  final _sessionController = StreamController<Session?>.broadcast();

  @override
  Future<Session> createSession(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Clear question cache so new team gets a fresh random set
    QuestionLoader.clearCache();
    final now = DateTime.now();
    _activeSession = Session(
      id: _uuid.v4().substring(0, 8),
      teamId: teamId,
      startTime: now,
      endTime: now.add(
        Duration(minutes: AppConfig.sessionDurationMinutes),
      ),
      score: 0,
      totalAnswered: 0,
      correctAnswers: 0,
      currentDifficulty: ChallengeDifficulty.easy,
      completedChallengeIds: [],
      skippedChallengeIds: [],
      isActive: true,
    );
    _sessionController.add(_activeSession);
    return _activeSession!;
  }

  @override
  Future<Session?> getActiveSession(String teamId) async {
    return _activeSession;
  }

  @override
  Stream<Session?> sessionStream(String teamId) async* {
    // Emit current value immediately
    yield _activeSession;
    // Then yield all future updates
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

  /// Internal helper to update score (called by mock challenge repo)
  void updateScore(int newScore, String challengeId, bool correct) {
    if (_activeSession == null) return;
    final completed = List<String>.from(_activeSession!.completedChallengeIds);
    if (correct) completed.add(challengeId);

    ChallengeDifficulty newDiff = _activeSession!.currentDifficulty;
    if (newScore >= 300) {
      newDiff = ChallengeDifficulty.expert;
    } else if (newScore >= 150) {
      newDiff = ChallengeDifficulty.hard;
    } else if (newScore >= 50) {
      newDiff = ChallengeDifficulty.medium;
    }

    _activeSession = _activeSession!.copyWith(
      score: newScore,
      totalAnswered: _activeSession!.totalAnswered + 1,
      correctAnswers: _activeSession!.correctAnswers + (correct ? 1 : 0),
      completedChallengeIds: completed,
      currentDifficulty: newDiff,
    );
    _sessionController.add(_activeSession);
  }

  void skipChallenge(String challengeId) {
    if (_activeSession == null) return;
    final skipped = List<String>.from(_activeSession!.skippedChallengeIds);
    skipped.add(challengeId);
    _activeSession = _activeSession!.copyWith(
      skippedChallengeIds: skipped,
      totalAnswered: _activeSession!.totalAnswered + 1,
    );
    _sessionController.add(_activeSession);
  }
}

// ═══════════════════════════════════════════════════
// MOCK CHALLENGE REPOSITORY
// ═══════════════════════════════════════════════════
class MockChallengeRepository implements ChallengeRepository {
  final MockSessionRepository _sessionRepo;
  final MockAuthRepository _authRepo;

  MockChallengeRepository(this._sessionRepo, this._authRepo);

  /// Cached challenges loaded from JSON (team-specific)
  List<Challenge>? _challenges;

  /// Load challenges for the current team (lazy, cached per team).
  Future<List<Challenge>> _loadChallenges() async {
    final teamId = _authRepo.currentTeam?.id ?? '__default__';
    _challenges ??= await QuestionLoader.loadQuestionsForTeam(teamId);
    return _challenges!;
  }

  /// Clear cached challenges (call when starting a new session).
  void clearCache() {
    _challenges = null;
    QuestionLoader.clearCache();
  }

  @override
  Future<List<Challenge>> getChallenges() async {
    return _loadChallenges();
  }

  @override
  Future<List<Challenge>> getChallengesByDifficulty(
      ChallengeDifficulty difficulty) async {
    final all = await _loadChallenges();
    return all.where((c) => c.difficulty == difficulty).toList();
  }

  @override
  Future<Challenge> getChallengeById(String challengeId) async {
    final all = await _loadChallenges();
    return all.firstWhere((c) => c.id == challengeId);
  }

  @override
  Future<SubmissionResult> submitAnswer({
    required String sessionId,
    required String challengeId,
    required String answer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate latency

    final challenges = await _loadChallenges();
    final challenge = challenges.firstWhere((c) => c.id == challengeId);
    final correctAnswer = QuestionLoader.answerMap[challengeId] ?? '';
    final isCorrect =
        answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    final points = isCorrect ? challenge.points : 0;
    final currentSession = await _sessionRepo.getActiveSession('');
    final newScore = (currentSession?.score ?? 0) + points;

    // Update mock session
    _sessionRepo.updateScore(newScore, challengeId, isCorrect);

    return SubmissionResult(
      isCorrect: isCorrect,
      pointsAwarded: points,
      newTotalScore: newScore,
      feedback: isCorrect
          ? 'Correct! 🎉'
          : 'Incorrect. The answer was: $correctAnswer',
    );
  }

  @override
  Future<int> skipChallenge({
    required String sessionId,
    required String challengeId,
  }) async {
    _sessionRepo.skipChallenge(challengeId);
    return AppConfig.skipPenalty;
  }

  @override
  Future<List<Challenge>> getAvailableChallenges({
    required String sessionId,
    required ChallengeDifficulty difficulty,
  }) async {
    final all = await _loadChallenges();
    final session = await _sessionRepo.getActiveSession('');
    final completedIds = session?.completedChallengeIds ?? [];
    final skippedIds = session?.skippedChallengeIds ?? [];
    return all
        .where(
            (c) => !completedIds.contains(c.id) && !skippedIds.contains(c.id))
        .toList();
  }
}

// ═══════════════════════════════════════════════════
// MOCK LEADERBOARD REPOSITORY
// ═══════════════════════════════════════════════════
class MockLeaderboardRepository implements LeaderboardRepository {
  final _controller = StreamController<List<LeaderboardEntry>>.broadcast();

  final List<LeaderboardEntry> _entries = [
    LeaderboardEntry(
      teamId: 'bot1',
      teamName: 'CyberNinjas',
      score: 185,
      completedCount: 6,
      rank: 1,
      lastUpdated: DateTime.now(),
    ),
    LeaderboardEntry(
      teamId: 'bot2',
      teamName: 'ByteBlasters',
      score: 140,
      completedCount: 5,
      rank: 2,
      lastUpdated: DateTime.now(),
    ),
    LeaderboardEntry(
      teamId: 'bot3',
      teamName: 'AlgoStorm',
      score: 95,
      completedCount: 4,
      rank: 3,
      lastUpdated: DateTime.now(),
    ),
    LeaderboardEntry(
      teamId: 'bot4',
      teamName: 'CodeCrafters',
      score: 60,
      completedCount: 3,
      rank: 4,
      lastUpdated: DateTime.now(),
    ),
    LeaderboardEntry(
      teamId: 'bot5',
      teamName: 'HackMatrix',
      score: 30,
      completedCount: 2,
      rank: 5,
      lastUpdated: DateTime.now(),
    ),
  ];

  MockLeaderboardRepository();

  @override
  Stream<List<LeaderboardEntry>> get leaderboardStream async* {
    yield List.from(_entries);
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
    // Update or insert
    final idx = _entries.indexWhere((e) => e.teamId == teamId);
    final entry = LeaderboardEntry(
      teamId: teamId,
      teamName: teamName,
      score: score,
      completedCount: completedCount,
      rank: 0,
      lastUpdated: DateTime.now(),
    );
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.add(entry);
    }
    // Re-sort and assign ranks
    _entries.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < _entries.length; i++) {
      _entries[i] = _entries[i].copyWith(rank: i + 1);
    }
    _controller.add(List.from(_entries));
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    return _entries;
  }
}
