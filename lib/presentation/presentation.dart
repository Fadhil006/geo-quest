/// Presentation layer — UI screens, state providers, and widgets.
///
/// ```
/// presentation/
/// ├── providers/   Riverpod state management (auth, challenge, session, etc.)
/// ├── screens/     Full-page screen widgets organized by feature
/// │   ├── admin/       Admin panel for challenge & session management
/// │   ├── auth/        Login and registration screens
/// │   ├── challenge/   Active challenge solving screen
/// │   ├── home/        Dashboard with stats and session countdown
/// │   ├── leaderboard/ Real-time team rankings
/// │   └── map/         Google Maps with challenge markers
/// └── widgets/     Reusable UI components organized by feature
///     ├── challenge/   Timer bar, etc.
///     ├── common/      Shared widgets (category chip, etc.)
///     ├── home/        Countdown, stat cards
///     └── map/         Challenge bottom sheet
/// ```
library;

export 'providers/providers.dart';
export 'screens/screens.dart';
export 'widgets/widgets.dart';
