/// GeoQuest — Sample Challenge Seed Data
///
/// This file provides sample challenge data for seeding Firestore.
/// Use this with Firebase Admin SDK or paste into Firestore Console.
///
/// USAGE:
///   1. Via Firebase Console: Copy each challenge JSON into the 'challenges' collection
///   2. Via Admin SDK script: Import and batch-write to Firestore
///   3. Via the app: Run the _seedChallenges() function from admin panel
///
/// IMPORTANT: Store answers in a SEPARATE 'challenge_answers' collection
/// that is NOT readable by clients. Only Cloud Functions should access answers.

library;

/// Sample challenges for a typical university campus
/// Replace coordinates with your actual campus locations
final List<Map<String, dynamic>> sampleChallenges = [
  // ══════════════════════════════════════
  // EASY CHALLENGES (0-50 pts range)
  // ══════════════════════════════════════
  {
    'title': 'Binary Basics',
    'description': 'A warm-up challenge about binary number systems. '
        'Find this challenge near the main library entrance.',
    'category': 'logicalReasoning',
    'difficulty': 'easy',
    'type': 'multipleChoice',
    'location': {'latitude': 9.754914, 'longitude': 76.649674}, // IIIT Kottayam campus
    'geofenceRadius': 20,
    'points': 10,
    'timeLimitSeconds': 180,
    'question': 'What is the decimal equivalent of the binary number 10110?',
    'options': ['18', '22', '26', '30'],
    'isActive': true,
  },
  {
    'title': 'Hello World Hunt',
    'description': 'A simple debugging challenge. '
        'Head to the Computer Science building entrance.',
    'category': 'codeDebugging',
    'difficulty': 'easy',
    'type': 'multipleChoice',
    'location': {'latitude': 9.7553, 'longitude': 76.6503},
    'geofenceRadius': 20,
    'points': 10,
    'timeLimitSeconds': 120,
    'question': 'What is wrong with this Python code?\n\n'
        'def greet(name)\n'
        '    print(f"Hello, {name}!")\n\n'
        'greet("World")',
    'options': [
      'Missing colon after function definition',
      'f-string not supported',
      'print is not a function',
      'Missing return statement'
    ],
    'isActive': true,
  },
  {
    'title': 'Pattern Spotter',
    'description': 'Find the pattern in this sequence. '
        'Located near the campus cafeteria.',
    'category': 'mathPuzzle',
    'difficulty': 'easy',
    'type': 'textInput',
    'location': {'latitude': 9.7543, 'longitude': 76.6490},
    'geofenceRadius': 20,
    'points': 10,
    'timeLimitSeconds': 150,
    'question': 'What is the next number in the sequence?\n\n'
        '2, 6, 12, 20, 30, ?',
    'isActive': true,
  },

  // ══════════════════════════════════════
  // MEDIUM CHALLENGES (50-150 pts range)
  // ══════════════════════════════════════
  {
    'title': 'Stack Overflow',
    'description': 'Test your knowledge of data structures. '
        'Find this near the Engineering Lab.',
    'category': 'algorithmOutput',
    'difficulty': 'medium',
    'type': 'textInput',
    'location': {'latitude': 9.7558, 'longitude': 76.6508},
    'geofenceRadius': 20,
    'points': 25,
    'timeLimitSeconds': 180,
    'question': 'Given a stack with operations:\n'
        'PUSH 5, PUSH 3, PUSH 8, POP, PUSH 2, POP, POP\n\n'
        'What element is left on top of the stack?',
    'isActive': true,
  },
  {
    'title': 'SQL Detective',
    'description': 'Decode the database query. '
        'Head to the admin building.',
    'category': 'technicalReasoning',
    'difficulty': 'medium',
    'type': 'multipleChoice',
    'location': {'latitude': 9.7563, 'longitude': 76.6500},
    'geofenceRadius': 20,
    'points': 25,
    'timeLimitSeconds': 180,
    'question': 'Given tables: students(id, name, dept_id) and departments(id, name)\n\n'
        'SELECT s.name FROM students s\n'
        'LEFT JOIN departments d ON s.dept_id = d.id\n'
        'WHERE d.id IS NULL;\n\n'
        'What does this query return?',
    'options': [
      'Students with no department assigned',
      'All students with their department names',
      'Departments with no students',
      'Students in the NULL department'
    ],
    'isActive': true,
  },
  {
    'title': 'Recursion Riddle',
    'description': 'Trace through this recursive function. '
        'Located by the campus fountain.',
    'category': 'algorithmOutput',
    'difficulty': 'medium',
    'type': 'textInput',
    'location': {'latitude': 9.7551, 'longitude': 76.6505},
    'geofenceRadius': 20,
    'points': 30,
    'timeLimitSeconds': 180,
    'question': 'What is the output of this function call?\n\n'
        'def mystery(n):\n'
        '    if n <= 1:\n'
        '        return 1\n'
        '    return n * mystery(n - 1)\n\n'
        'print(mystery(5))',
    'isActive': true,
  },

  // ══════════════════════════════════════
  // HARD CHALLENGES (150-300 pts range)
  // ══════════════════════════════════════
  {
    'title': 'Time Complexity Master',
    'description': 'Analyze the algorithmic complexity. '
        'Hidden near the research center.',
    'category': 'technicalReasoning',
    'difficulty': 'hard',
    'type': 'multipleChoice',
    'location': {'latitude': 9.7568, 'longitude': 76.6512},
    'geofenceRadius': 20,
    'points': 50,
    'timeLimitSeconds': 180,
    'question': 'What is the time complexity of this code?\n\n'
        'for i in range(n):\n'
        '    j = 1\n'
        '    while j < n:\n'
        '        j *= 2\n'
        '        # O(1) operation',
    'options': [
      'O(n log n)',
      'O(n²)',
      'O(n)',
      'O(n * 2ⁿ)'
    ],
    'isActive': true,
  },
  {
    'title': 'Bit Manipulation Blitz',
    'description': 'Low-level thinking required. '
        'Located at the sports complex.',
    'category': 'logicalReasoning',
    'difficulty': 'hard',
    'type': 'textInput',
    'location': {'latitude': 9.7538, 'longitude': 76.6485},
    'geofenceRadius': 20,
    'points': 50,
    'timeLimitSeconds': 180,
    'question': 'What is the result of the following operations?\n\n'
        'a = 0b11010110\n'
        'b = 0b10101010\n'
        'result = (a ^ b) & 0xFF\n\n'
        'Express your answer in decimal.',
    'isActive': true,
  },

  // ══════════════════════════════════════
  // EXPERT CHALLENGES (300+ pts range)
  // ══════════════════════════════════════
  {
    'title': 'Dynamic Programming Gauntlet',
    'description': 'The ultimate coding challenge. '
        'Only the worthy will find this at the campus auditorium.',
    'category': 'algorithmOutput',
    'difficulty': 'expert',
    'type': 'textInput',
    'location': {'latitude': 9.7573, 'longitude': 76.6517},
    'geofenceRadius': 25,
    'points': 100,
    'timeLimitSeconds': 300,
    'question': 'Given the coin denominations [1, 3, 4] and a target sum of 6,\n'
        'what is the MINIMUM number of coins needed?\n\n'
        'Answer with just the number.',
    'isActive': true,
  },
  {
    'title': 'Graph Theory Enigma',
    'description': 'Navigate the graph of knowledge. '
        'The final challenge awaits at the main gate.',
    'category': 'logicalReasoning',
    'difficulty': 'expert',
    'type': 'multipleChoice',
    'location': {'latitude': 9.7533, 'longitude': 76.6480},
    'geofenceRadius': 25,
    'points': 100,
    'timeLimitSeconds': 300,
    'question': 'A directed graph has 6 vertices. Every vertex has an out-degree of 2 '
        'and an in-degree of 2. What is the minimum number of strongly '
        'connected components this graph can have?',
    'options': ['1', '2', '3', '6'],
    'isActive': true,
  },
];

/// Answers stored SEPARATELY — never sent to client
/// These go into the 'challenge_answers' collection
/// Key: challengeId (auto-generated), Value: correct answer
final List<Map<String, dynamic>> sampleAnswers = [
  // Easy
  {'answer': '22', 'challengeIndex': 0},
  {'answer': 'Missing colon after function definition', 'challengeIndex': 1},
  {'answer': '42', 'challengeIndex': 2},
  // Medium
  {'answer': '5', 'challengeIndex': 3},
  {'answer': 'Students with no department assigned', 'challengeIndex': 4},
  {'answer': '120', 'challengeIndex': 5},
  // Hard
  {'answer': 'O(n log n)', 'challengeIndex': 6},
  {'answer': '124', 'challengeIndex': 7},
  // Expert
  {'answer': '2', 'challengeIndex': 8},
  {'answer': '1', 'challengeIndex': 9},
];

