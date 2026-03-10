/// GeoQuest — Challenge Entity
/// Represents a GPS-bound challenge at a campus location
library;

enum ChallengeCategory {
  logicalReasoning,
  algorithmOutput,
  codeDebugging,
  mathPuzzle,
  technicalReasoning,
  observational,
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert,
}

enum ChallengeType {
  multipleChoice,
  textInput,
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeType type;
  final double latitude;
  final double longitude;
  final double geofenceRadius; // meters
  final int points;
  final int timeLimitSeconds;
  final String question;
  final List<String>? options; // for multiple choice
  // NOTE: answer is NEVER stored on client — validated server-side only
  final bool isActive;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.geofenceRadius = 20.0,
    required this.points,
    this.timeLimitSeconds = 180,
    required this.question,
    this.options,
    this.isActive = true,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    ChallengeType? type,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    int? points,
    int? timeLimitSeconds,
    String? question,
    List<String>? options,
    bool? isActive,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      points: points ?? this.points,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      question: question ?? this.question,
      options: options ?? this.options,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Challenge && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

