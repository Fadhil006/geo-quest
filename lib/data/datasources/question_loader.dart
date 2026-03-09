import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/challenge.dart';

/// Loads questions from bundled JSON asset files and converts them
/// to [Challenge] entities used throughout the app.
class QuestionLoader {
  QuestionLoader._();

  /// Loaded questions cache (so we only read from disk once)
  static List<Challenge>? _cache;

  /// Answer map: challengeId → correct answer letter (e.g. "B")
  static final Map<String, String> _answerMap = {};

  /// Get the answer map (for mock validation)
  static Map<String, String> get answerMap => Map.unmodifiable(_answerMap);

  /// Load all questions from the `question/1.json` asset.
  /// Returns a list of [Challenge] objects with difficulty assigned
  /// based on question index tiers.
  static Future<List<Challenge>> loadQuestions() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString('question/1.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final questions = data['questions'] as List<dynamic>;

    final challenges = <Challenge>[];
    _answerMap.clear();

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      final id = 'q${q['id']}';
      final questionText = q['question'] as String;
      final optionsMap = q['options'] as Map<String, dynamic>;
      final answerKey = q['answer'] as String; // "A", "B", "C", or "D"

      // Build options list: ["A. text", "B. text", ...]
      final options = <String>[];
      for (final key in ['A', 'B', 'C', 'D']) {
        if (optionsMap.containsKey(key)) {
          options.add(optionsMap[key] as String);
        }
      }

      // Store answer as the full option text for validation
      final answerIndex = answerKey.codeUnitAt(0) - 'A'.codeUnitAt(0);
      final answerText =
          answerIndex < options.length ? options[answerIndex] : '';
      _answerMap[id] = answerText;

      // Assign difficulty based on question index tiers
      final difficulty = _difficultyForIndex(i, questions.length);

      // Assign category based on content heuristics
      final category = _categoryForQuestion(i, questionText);

      // Points scale with difficulty
      final points = _pointsForDifficulty(difficulty);

      // Time limit scales with difficulty
      final timeLimit = _timeLimitForDifficulty(difficulty);

      // Spread GPS coordinates around a campus center
      final coords = _coordinatesForIndex(i, questions.length);

      challenges.add(Challenge(
        id: id,
        title: 'Challenge ${q['id']}',
        description: _descriptionForCategory(category),
        category: category,
        difficulty: difficulty,
        type: ChallengeType.multipleChoice,
        latitude: coords.$1,
        longitude: coords.$2,
        points: points,
        timeLimitSeconds: timeLimit,
        question: questionText,
        options: options,
      ));
    }

    _cache = challenges;
    return challenges;
  }

  /// Clear the cache (useful for testing or hot-reload)
  static void clearCache() {
    _cache = null;
    _answerMap.clear();
  }

  // ── Difficulty assignment ──
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

  // Spread challenges in a circle around campus center
  static (double lat, double lng) _coordinatesForIndex(int index, int total) {
    const centerLat = 22.5726;
    const centerLng = 88.3639;
    const radius = 0.003; // ~300m spread

    final angle = (index / total) * 2 * 3.14159265;
    final lat = centerLat + radius * _cos(angle);
    final lng = centerLng + radius * _sin(angle);
    return (lat, lng);
  }

  static double _sin(double x) {
    // Simple sin approximation (avoids dart:math import for this utility)
    x = x % (2 * 3.14159265);
    double result = x;
    double term = x;
    for (int i = 1; i <= 7; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(x + 3.14159265 / 2);
}
