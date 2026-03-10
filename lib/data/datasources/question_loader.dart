import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/challenge.dart';

/// How many questions each team gets per difficulty tier.
/// Total per team = perTier × 4 (easy + medium + hard + expert).
const int _questionsPerTier = 5;

/// Loads questions from bundled JSON asset files and converts them
/// to [Challenge] entities used throughout the app.
///
/// Each team receives a **different, randomly-selected and shuffled**
/// subset of questions. The selection is deterministic per team ID
/// so reloading gives the same set.  GPS marker positions are also
/// randomised per team.
class QuestionLoader {
  QuestionLoader._();

  /// Loaded questions cache — keyed by team ID.
  static String? _cachedTeamId;
  static List<Challenge>? _cache;

  /// Answer map: challengeId → correct answer text
  static final Map<String, String> _answerMap = {};

  /// Get the answer map (for mock validation)
  static Map<String, String> get answerMap => Map.unmodifiable(_answerMap);

  // ─── Internal: load the full question bank (no caching of this) ───
  static Future<List<_RawQuestion>> _loadBank() async {
    final jsonString = await rootBundle.loadString('question/1.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final questions = data['questions'] as List<dynamic>;

    final bank = <_RawQuestion>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      final id = 'q${q['id']}';
      final questionText = q['question'] as String;
      final optionsMap = q['options'] as Map<String, dynamic>;
      final answerKey = q['answer'] as String;

      final options = <String>[];
      for (final key in ['A', 'B', 'C', 'D']) {
        if (optionsMap.containsKey(key)) {
          options.add(optionsMap[key] as String);
        }
      }

      final answerIndex = answerKey.codeUnitAt(0) - 'A'.codeUnitAt(0);
      final answerText =
          answerIndex < options.length ? options[answerIndex] : '';

      // Difficulty assigned by position in the JSON (unchanged)
      final difficulty = _difficultyForIndex(i, questions.length);

      bank.add(_RawQuestion(
        id: id,
        originalIndex: i,
        questionText: questionText,
        options: options,
        answerText: answerText,
        difficulty: difficulty,
      ));
    }
    return bank;
  }

  /// Load a **team-specific** set of questions.
  ///
  /// * Picks [_questionsPerTier] questions from each difficulty bucket
  ///   (easy, medium, hard, expert) using the team's hash as seed.
  /// * Shuffles the final list so question order is random per team.
  /// * Assigns GPS coordinates randomly (but deterministically) per team.
  static Future<List<Challenge>> loadQuestionsForTeam(String teamId) async {
    // Return cache if we already built this team's set
    if (_cachedTeamId == teamId && _cache != null) return _cache!;

    final bank = await _loadBank();

    // Deterministic RNG seeded from team ID
    final seed = teamId.hashCode;
    final rng = Random(seed);

    // Group by difficulty
    final buckets = <ChallengeDifficulty, List<_RawQuestion>>{};
    for (final d in ChallengeDifficulty.values) {
      buckets[d] = bank.where((q) => q.difficulty == d).toList();
    }

    // Pick _questionsPerTier from each bucket (shuffle first, then take)
    final selected = <_RawQuestion>[];
    for (final d in ChallengeDifficulty.values) {
      final bucket = buckets[d]!;
      bucket.shuffle(rng);
      selected.addAll(bucket.take(_questionsPerTier));
    }

    // Shuffle the combined selection so difficulties are interleaved
    selected.shuffle(rng);

    // Build Challenge objects with team-random GPS positions
    _answerMap.clear();
    final challenges = <Challenge>[];

    for (int i = 0; i < selected.length; i++) {
      final q = selected[i];
      _answerMap[q.id] = q.answerText;

      final category = _categoryForQuestion(q.originalIndex, q.questionText);
      final points = _pointsForDifficulty(q.difficulty);
      final timeLimit = _timeLimitForDifficulty(q.difficulty);
      final coords = _randomCoordinates(rng);

      challenges.add(Challenge(
        id: q.id,
        title: 'Challenge ${q.id.substring(1)}', // strip leading 'q'
        description: _descriptionForCategory(category),
        category: category,
        difficulty: q.difficulty,
        type: ChallengeType.multipleChoice,
        latitude: coords.$1,
        longitude: coords.$2,
        points: points,
        timeLimitSeconds: timeLimit,
        question: q.questionText,
        options: q.options,
      ));
    }

    _cache = challenges;
    _cachedTeamId = teamId;
    return challenges;
  }

  /// Legacy entry point — loads ALL questions (no team filtering).
  /// Prefer [loadQuestionsForTeam] for gameplay.
  static Future<List<Challenge>> loadQuestions() async {
    return loadQuestionsForTeam('__default__');
  }

  /// Clear the cache (call when a new session starts)
  static void clearCache() {
    _cache = null;
    _cachedTeamId = null;
    _answerMap.clear();
  }

  // ── Difficulty assignment (by position in the JSON bank) ──
  // First ~30% = easy, next ~30% = medium, next ~25% = hard, last ~15% = expert
  static ChallengeDifficulty _difficultyForIndex(int index, int total) {
    final ratio = index / total;
    if (ratio < 0.30) return ChallengeDifficulty.easy;
    if (ratio < 0.60) return ChallengeDifficulty.medium;
    if (ratio < 0.85) return ChallengeDifficulty.hard;
    return ChallengeDifficulty.expert;
  }

  static int _pointsForDifficulty(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy:
        return 5;
      case ChallengeDifficulty.medium:
        return 10;
      case ChallengeDifficulty.hard:
        return 20;
      case ChallengeDifficulty.expert:
        return 20; // rapid fire base — may be 2× for shiny
    }
  }

  static int _timeLimitForDifficulty(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy:
        return 45;
      case ChallengeDifficulty.medium:
        return 120;
      case ChallengeDifficulty.hard:
        return 120;
      case ChallengeDifficulty.expert:
        return 30; // rapid fire: 30s per question
    }
  }

  // Assign categories based on question content keywords
  static ChallengeCategory _categoryForQuestion(int index, String question) {
    final q = question.toLowerCase();
    if (q.contains('output') || q.contains('print') || q.contains('printed')) {
      return ChallengeCategory.algorithmOutput;
    }
    if (q.contains('error') ||
        q.contains('bug') ||
        q.contains('debug') ||
        q.contains('wrong')) {
      return ChallengeCategory.codeDebugging;
    }
    if (q.contains('complexity') ||
        q.contains('sort') ||
        q.contains('algorithm') ||
        q.contains('data structure') ||
        q.contains('stack') ||
        q.contains('queue') ||
        q.contains('tree') ||
        q.contains('graph') ||
        q.contains('bfs') ||
        q.contains('dfs') ||
        q.contains('search') ||
        q.contains('traverse') ||
        q.contains('heap') ||
        q.contains('hash')) {
      return ChallengeCategory.logicalReasoning;
    }
    if (q.contains('math') ||
        q.contains('number') ||
        q.contains('sequence') ||
        q.contains('decimal') ||
        q.contains('binary')) {
      return ChallengeCategory.mathPuzzle;
    }
    if (q.contains('cpu') ||
        q.contains('ram') ||
        q.contains('memory') ||
        q.contains('gpu') ||
        q.contains('operating') ||
        q.contains('protocol') ||
        q.contains('sql') ||
        q.contains('dns') ||
        q.contains('api') ||
        q.contains('http')) {
      return ChallengeCategory.technicalReasoning;
    }
    // Fallback: rotate categories
    const categories = ChallengeCategory.values;
    return categories[index % categories.length];
  }

  static String _descriptionForCategory(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.logicalReasoning:
        return 'Test your logical thinking skills.';
      case ChallengeCategory.algorithmOutput:
        return 'Predict what the code will output.';
      case ChallengeCategory.codeDebugging:
        return 'Find and fix the bug.';
      case ChallengeCategory.mathPuzzle:
        return 'Solve the mathematical puzzle.';
      case ChallengeCategory.technicalReasoning:
        return 'Apply your technical knowledge.';
      case ChallengeCategory.observational:
        return 'Observe carefully and answer.';
    }
  }

  // Randomise GPS position inside the campus bounding box.
  // Uses the team-seeded [rng] so every team gets different positions.
  static (double lat, double lng) _randomCoordinates(Random rng) {
    const minLat = 22.5695;
    const maxLat = 22.5757;
    const minLng = 88.3604;
    const maxLng = 88.3674;

    final lat = minLat + rng.nextDouble() * (maxLat - minLat);
    final lng = minLng + rng.nextDouble() * (maxLng - minLng);
    return (lat, lng);
  }
}

/// Internal data class for a raw question before it becomes a [Challenge].
class _RawQuestion {
  final String id;
  final int originalIndex;
  final String questionText;
  final List<String> options;
  final String answerText;
  final ChallengeDifficulty difficulty;

  _RawQuestion({
    required this.id,
    required this.originalIndex,
    required this.questionText,
    required this.options,
    required this.answerText,
    required this.difficulty,
  });
}
