import 'dart:math';

/// GeoQuest — Geolocation Utility Functions
class GeoUtils {
  GeoUtils._();

  static const double earthRadiusMeters = 6371000.0;

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Check if a position is within the geofence radius of a target
  static bool isWithinRadius({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
    required double radiusMeters,
  }) {
    final distance = haversineDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radiusMeters;
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  /// Format coordinates for display
  static String formatCoordinate(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}

