/// GeoQuest — DateTime Utility Functions
class DateTimeUtils {
  DateTimeUtils._();

  /// Format duration as HH:MM:SS
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format duration as MM:SS (for challenge timers)
  static String formatMinSec(Duration duration) {
    if (duration.isNegative) return '00:00';

    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Calculate remaining time from a session end time
  static Duration remainingTime(DateTime endTime) {
    return endTime.difference(DateTime.now());
  }

  /// Check if a session has expired
  static bool isSessionExpired(DateTime endTime) {
    return DateTime.now().isAfter(endTime);
  }

  /// Progress fraction for a countdown (0.0 = full, 1.0 = expired)
  static double countdownProgress(DateTime startTime, DateTime endTime) {
    final total = endTime.difference(startTime).inMilliseconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Session duration constant
  static const Duration sessionDuration = Duration(hours: 2);

  /// Default challenge time limit
  static const Duration defaultChallengeTime = Duration(minutes: 3);
}

