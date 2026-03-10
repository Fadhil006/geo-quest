import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/team.dart';

/// Firestore data model for Team
class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.teamName,
    required super.members,
    required super.createdAt,
    super.sessionId,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      teamName: data['teamName'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionId: data['sessionId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamName': teamName,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'sessionId': sessionId,
    };
  }

  factory TeamModel.fromEntity(Team team) {
    return TeamModel(
      id: team.id,
      teamName: team.teamName,
      members: team.members,
      createdAt: team.createdAt,
      sessionId: team.sessionId,
    );
  }
}

