import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge.dart';

/// Firestore data model for Challenge
class ChallengeModel extends Challenge {
  const ChallengeModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.difficulty,
    required super.type,
    required super.latitude,
    required super.longitude,
    super.geofenceRadius,
    required super.points,
    super.timeLimitSeconds,
    required super.question,
    super.options,
    super.isActive,
  });

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint?;

    return ChallengeModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: _categoryFromString(data['category']),
      difficulty: _difficultyFromString(data['difficulty']),
      type: data['type'] == 'multipleChoice'
          ? ChallengeType.multipleChoice
          : ChallengeType.textInput,
      latitude: geoPoint?.latitude ?? 0,
      longitude: geoPoint?.longitude ?? 0,
      geofenceRadius: (data['geofenceRadius'] ?? 20).toDouble(),
      points: data['points'] ?? 10,
      timeLimitSeconds: data['timeLimitSeconds'] ?? 180,
      question: data['question'] ?? '',
      options: data['options'] != null
          ? List<String>.from(data['options'])
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'type': type == ChallengeType.multipleChoice ? 'multipleChoice' : 'textInput',
      'location': GeoPoint(latitude, longitude),
      'geofenceRadius': geofenceRadius,
      'points': points,
      'timeLimitSeconds': timeLimitSeconds,
      'question': question,
      'options': options,
      'isActive': isActive,
    };
  }

  static ChallengeCategory _categoryFromString(String? value) {
    return ChallengeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChallengeCategory.logicalReasoning,
    );
  }

  static ChallengeDifficulty _difficultyFromString(String? value) {
    return ChallengeDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChallengeDifficulty.easy,
    );
  }
}

