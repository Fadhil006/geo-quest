/// GeoQuest — App configuration
/// Toggle offline mode to run without Firebase / Google Maps setup.
class AppConfig {
  /// Set to `true` to run the app entirely offline with mock data.
  /// Set to `false` when Firebase + Google Maps are configured.
  static const bool offlineMode = true;

  /// Set to `true` to enable real GPS location tracking.
  /// Works independently of offlineMode — you can use GPS with mock data.
  static const bool gpsEnabled = true;

  /// Session duration in minutes (default 120 = 2 hours)
  static const int sessionDurationMinutes = 120;

  /// Geofence unlock radius in meters
  static const double defaultGeofenceRadius = 30.0;

  /// Skip penalty in points
  static const int skipPenalty = 0;

  /// Target score to win
  static const int targetScore = 500;
}
