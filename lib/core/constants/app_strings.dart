/// GeoQuest — Application Strings
class AppStrings {
  AppStrings._();

  // ── App ──
  static const String appName = 'GeoQuest';
  static const String appTagline = 'A Campus-Wide GPS Challenge';
  static const String appVersion = '1.0.0';

  // ── Auth ──
  static const String registerTeam = 'Register Team';
  static const String loginTeam = 'Login';
  static const String teamName = 'Team Name';
  static const String teamId = 'Team ID';
  static const String memberName = 'Member Name';
  static const String addMember = 'Add Member';
  static const String removeMember = 'Remove';
  static const String enterTeamId = 'Enter your Team ID';
  static const String createTeam = 'Create Team';
  static const String joinEvent = 'Join the Quest';
  static const String alreadyRegistered = 'Already registered?';
  static const String newTeam = 'New team?';

  // ── Dashboard ──
  static const String dashboard = 'Dashboard';
  static const String remainingTime = 'Remaining Time';
  static const String currentScore = 'Current Score';
  static const String difficulty = 'Difficulty';
  static const String activeChallenges = 'Active Challenges';
  static const String viewMap = 'View Map';
  static const String leaderboard = 'Leaderboard';
  static const String startQuest = 'Start Quest';
  static const String resumeQuest = 'Resume Quest';
  static const String questComplete = 'Quest Complete!';
  static const String timeExpired = 'Time Expired';

  // ── Difficulty Labels ──
  static const String easy = 'Easy';
  static const String medium = 'Medium';
  static const String hard = 'Hard';
  static const String expert = 'Expert';

  // ── Challenge ──
  static const String submit = 'Submit';
  static const String skip = 'Skip';
  static const String skipPenalty = '-10 pts penalty';
  static const String correct = 'Correct!';
  static const String incorrect = 'Incorrect!';
  static const String challengeUnlocked = 'Challenge Unlocked!';
  static const String approachLocation = 'Approach the location to unlock';

  // ── Categories ──
  static const String logicalReasoning = 'Logical Reasoning';
  static const String algorithmOutput = 'Algorithm Output';
  static const String codeDebugging = 'Code Debugging';
  static const String mathPuzzle = 'Math Puzzle';
  static const String technicalReasoning = 'Technical Reasoning';
  static const String observational = 'Observational';

  // ── Leaderboard ──
  static const String leaderboardTitle = 'Live Leaderboard';
  static const String yourTeam = 'Your Team';
  static const String rank = 'Rank';
  static const String score = 'Score';
  static const String noTeamsYet = 'No teams on the board yet';

  // ── Errors ──
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorLocation = 'Unable to access location.';
  static const String errorNetwork = 'Check your internet connection.';
  static const String errorSessionExpired = 'Your session has expired.';
  static const String errorMinMembers = 'Team must have at least 3 members.';
  static const String errorMaxMembers = 'Team can have at most 4 members.';
}

