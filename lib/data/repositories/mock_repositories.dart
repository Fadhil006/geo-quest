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
      correctAnswers:
          _activeSession!.correctAnswers + (correct ? 1 : 0),
      completedChallengeIds: completed,
      currentDifficulty: newDiff,
    );
    _sessionController.add(_activeSession);
  }

  void skipChallenge(String challengeId) {
    if (_activeSession == null) return;
    final skipped = List<String>.from(_activeSession!.skippedChallengeIds);
    skipped.add(challengeId);
    final newScore = (_activeSession!.score - AppConfig.skipPenalty)
        .clamp(0, 999999);
    _activeSession = _activeSession!.copyWith(
      score: newScore,
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

  MockChallengeRepository(this._sessionRepo);

  /// Offline answers map (challenge index → correct answer)
  static const Map<int, String> _answers = {
    0: '22',
    1: 'missing colon after function definition',
    2: '42',
    3: '5',
    4: 'students with no department assigned',
    5: '120',
    6: 'o(n log n)',
    7: '124',
    8: '2',
    9: '1',
  };

  static final List<Challenge> _challenges = [
    // ── Easy ──
    const Challenge(
      id: 'c001',
      title: 'Binary Basics',
      description: 'A warm-up challenge about binary number systems.',
      category: ChallengeCategory.logicalReasoning,
      difficulty: ChallengeDifficulty.easy,
      type: ChallengeType.multipleChoice,
      latitude: 22.5726,
      longitude: 88.3639,
      points: 10,
      timeLimitSeconds: 180,
      question: 'What is the decimal equivalent of the binary number 10110?',
      options: ['18', '22', '26', '30'],
    ),
    const Challenge(
      id: 'c002',
      title: 'Hello World Hunt',
      description: 'A simple debugging challenge.',
      category: ChallengeCategory.codeDebugging,
      difficulty: ChallengeDifficulty.easy,
      type: ChallengeType.multipleChoice,
      latitude: 22.5730,
      longitude: 88.3645,
      points: 10,
      timeLimitSeconds: 120,
      question:
          'What is wrong with this Python code?\n\ndef greet(name)\n    print(f"Hello, {name}!")\n\ngreet("World")',
      options: [
        'Missing colon after function definition',
        'f-string not supported',
        'print is not a function',
        'Missing return statement'
      ],
    ),
    const Challenge(
      id: 'c003',
      title: 'Pattern Spotter',
      description: 'Find the pattern in this sequence.',
      category: ChallengeCategory.mathPuzzle,
      difficulty: ChallengeDifficulty.easy,
      type: ChallengeType.textInput,
      latitude: 22.5720,
      longitude: 88.3635,
      points: 10,
      timeLimitSeconds: 150,
      question:
          'What is the next number in the sequence?\n\n2, 6, 12, 20, 30, ?',
    ),
    // ── Medium ──
    const Challenge(
      id: 'c004',
      title: 'Stack Overflow',
      description: 'Test your knowledge of data structures.',
      category: ChallengeCategory.algorithmOutput,
      difficulty: ChallengeDifficulty.medium,
      type: ChallengeType.textInput,
      latitude: 22.5735,
      longitude: 88.3650,
      points: 25,
      timeLimitSeconds: 180,
      question:
          'Given a stack with operations:\nPUSH 5, PUSH 3, PUSH 8, POP, PUSH 2, POP, POP\n\nWhat element is left on top of the stack?',
    ),
    const Challenge(
      id: 'c005',
      title: 'SQL Detective',
      description: 'Decode the database query.',
      category: ChallengeCategory.technicalReasoning,
      difficulty: ChallengeDifficulty.medium,
      type: ChallengeType.multipleChoice,
      latitude: 22.5740,
      longitude: 88.3642,
      points: 25,
      timeLimitSeconds: 180,
      question:
          'Given tables: students(id, name, dept_id) and departments(id, name)\n\nSELECT s.name FROM students s\nLEFT JOIN departments d ON s.dept_id = d.id\nWHERE d.id IS NULL;\n\nWhat does this query return?',
      options: [
        'Students with no department assigned',
        'All students with their department names',
        'Departments with no students',
        'Students in the NULL department'
      ],
    ),
    const Challenge(
      id: 'c006',
      title: 'Recursion Riddle',
      description: 'Trace through this recursive function.',
      category: ChallengeCategory.algorithmOutput,
      difficulty: ChallengeDifficulty.medium,
      type: ChallengeType.textInput,
      latitude: 22.5728,
      longitude: 88.3648,
      points: 30,
      timeLimitSeconds: 180,
      question:
          'What is the output of this function call?\n\ndef mystery(n):\n    if n <= 1:\n        return 1\n    return n * mystery(n - 1)\n\nprint(mystery(5))',
    ),
    // ── Hard ──
    const Challenge(
      id: 'c007',
      title: 'Time Complexity Master',
      description: 'Analyze the algorithmic complexity.',
      category: ChallengeCategory.technicalReasoning,
      difficulty: ChallengeDifficulty.hard,
      type: ChallengeType.multipleChoice,
      latitude: 22.5745,
      longitude: 88.3655,
      points: 50,
      timeLimitSeconds: 180,
      question:
          'What is the time complexity of this code?\n\nfor i in range(n):\n    j = 1\n    while j < n:\n        j *= 2',
      options: ['O(n log n)', 'O(n²)', 'O(n)', 'O(n * 2ⁿ)'],
    ),
    const Challenge(
      id: 'c008',
      title: 'Bit Manipulation Blitz',
      description: 'Low-level thinking required.',
      category: ChallengeCategory.logicalReasoning,
      difficulty: ChallengeDifficulty.hard,
      type: ChallengeType.textInput,
      latitude: 22.5715,
      longitude: 88.3630,
      points: 50,
      timeLimitSeconds: 180,
      question:
          'What is the result of the following operations?\n\na = 0b11010110\nb = 0b10101010\nresult = (a ^ b) & 0xFF\n\nExpress your answer in decimal.',
    ),
    // ── Expert ──
    const Challenge(
      id: 'c009',
      title: 'Dynamic Programming Gauntlet',
      description: 'The ultimate coding challenge.',
      category: ChallengeCategory.algorithmOutput,
      difficulty: ChallengeDifficulty.expert,
      type: ChallengeType.textInput,
      latitude: 22.5750,
      longitude: 88.3660,
      geofenceRadius: 25,
      points: 100,
      timeLimitSeconds: 300,
      question:
          'Given the coin denominations [1, 3, 4] and a target sum of 6,\nwhat is the MINIMUM number of coins needed?\n\nAnswer with just the number.',
    ),
    const Challenge(
      id: 'c010',
      title: 'Graph Theory Enigma',
      description: 'Navigate the graph of knowledge.',
      category: ChallengeCategory.logicalReasoning,
      difficulty: ChallengeDifficulty.expert,
      type: ChallengeType.multipleChoice,
      latitude: 22.5710,
      longitude: 88.3625,
      geofenceRadius: 25,
      points: 100,
      timeLimitSeconds: 300,
      question:
          'A directed graph has 6 vertices. Every vertex has an out-degree of 2 '
          'and an in-degree of 2. What is the minimum number of strongly '
          'connected components this graph can have?',
      options: ['1', '2', '3', '6'],
    ),
  ];

  @override
  Future<List<Challenge>> getChallenges() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _challenges;
  }

  @override
  Future<List<Challenge>> getChallengesByDifficulty(
      ChallengeDifficulty difficulty) async {
    return _challenges.where((c) => c.difficulty == difficulty).toList();
  }

  @override
  Future<Challenge> getChallengeById(String challengeId) async {
    return _challenges.firstWhere((c) => c.id == challengeId);
  }

  @override
  Future<SubmissionResult> submitAnswer({
    required String sessionId,
    required String challengeId,
    required String answer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate latency

    final idx = _challenges.indexWhere((c) => c.id == challengeId);
    final correctAnswer = _answers[idx] ?? '';
    final isCorrect =
        answer.trim().toLowerCase() == correctAnswer.toLowerCase();

    final challenge = _challenges[idx];
    final points = isCorrect ? challenge.points : 0;
    final currentSession = await _sessionRepo.getActiveSession('');
    final newScore = (currentSession?.score ?? 0) + points;

    // Update mock session
    _sessionRepo.updateScore(newScore, challengeId, isCorrect);

    return SubmissionResult(
      isCorrect: isCorrect,
      pointsAwarded: points,
      newTotalScore: newScore,
      feedback: isCorrect ? 'Correct! 🎉' : 'Incorrect. The answer was: $correctAnswer',
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
    final session = await _sessionRepo.getActiveSession('');
    final completedIds = session?.completedChallengeIds ?? [];
    final skippedIds = session?.skippedChallengeIds ?? [];
    return _challenges
        .where((c) =>
            !completedIds.contains(c.id) && !skippedIds.contains(c.id))
        .toList();
  }
}

// ═══════════════════════════════════════════════════
// MOCK LEADERBOARD REPOSITORY
// ═══════════════════════════════════════════════════
class MockLeaderboardRepository implements LeaderboardRepository {
  final _controller =
      StreamController<List<LeaderboardEntry>>.broadcast();

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

