/// GeoQuest — Spawn Location Entity
/// A GPS point where questions can be triggered
class SpawnLocation {
  final String spawnLocationId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? label;

  const SpawnLocation({
    required this.spawnLocationId,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 20.0,
    this.label,
  });

  factory SpawnLocation.fromJson(Map<String, dynamic> json) {
    return SpawnLocation(
      spawnLocationId: json['spawnLocationId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 20.0,
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpawnLocation &&
          spawnLocationId == other.spawnLocationId;

  @override
  int get hashCode => spawnLocationId.hashCode;
}
