/// GeoQuest — Team Entity
class Team {
  final String id;
  final String teamName;
  final List<String> members;
  final DateTime createdAt;
  final String? sessionId;

  const Team({
    required this.id,
    required this.teamName,
    required this.members,
    required this.createdAt,
    this.sessionId,
  });

  Team copyWith({
    String? id,
    String? teamName,
    List<String>? members,
    DateTime? createdAt,
    String? sessionId,
  }) {
    return Team(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Team && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

