/// GeoQuest — Firebase Collection Paths & Database References
class FirebasePaths {
  FirebasePaths._();

  // ── Firestore Collections ──
  static const String teams = 'teams';
  static const String challenges = 'challenges';
  static const String sessions = 'sessions';
  static const String submissions = 'submissions';
  static const String eventConfig = 'event_config';

  // ── Realtime Database Refs ──
  static const String leaderboard = 'leaderboard';
  static const String activeTimers = 'active_timers';
  static const String liveScores = 'live_scores';

  // ── Firestore Field Names ──
  static const String teamId = 'teamId';
  static const String teamName = 'teamName';
  static const String members = 'members';
  static const String score = 'score';
  static const String startTime = 'startTime';
  static const String endTime = 'endTime';
  static const String isActive = 'isActive';
  static const String difficultyLevel = 'difficultyLevel';
  static const String completedChallenges = 'completedChallenges';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String category = 'category';
  static const String points = 'points';
  static const String answer = 'answer';
}

