/// GeoQuest — App configuration
/// Toggle offline mode to run without Firebase / Google Maps setup.
class AppConfig {
  /// Set to `true` to run the app entirely offline with mock data.
  /// Set to `false` when Firebase + Google Maps are configured.
  static const bool offlineMode = true;

  /// Session duration in minutes (default 120 = 2 hours)
  static const int sessionDurationMinutes = 120;

  /// Geofence unlock radius in meters
  static const double defaultGeofenceRadius = 20.0;

  /// Skip penalty in points
  static const int skipPenalty = 10;

  /// Target score to win
  static const int targetScore = 500;
}

