/// Core layer — shared constants, theming, utilities, widgets, and stubs.
///
/// ```
/// core/
/// ├── constants/    App-wide configuration, colors, strings, asset paths
/// ├── stubs/        Firebase stub implementations for offline mode
/// ├── theme/        Material theme data and glassmorphism helpers
/// ├── utils/        Date/time and geolocation utilities
/// └── widgets/      Reusable UI building blocks (scaffold, buttons, app bar)
/// ```
library;

export 'constants/constants.dart';
export 'stubs/firebase_stubs.dart';
export 'theme/theme.dart';
export 'utils/utils.dart';
export 'widgets/widgets.dart';
