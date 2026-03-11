/// Barrel file for repository implementations.
///
/// Note: Firebase-backed implementations (auth_repository_impl.dart,
/// challenge_repository_impl.dart, etc.) are not exported here because their
/// Firebase packages are intentionally disabled in pubspec.yaml for offline mode.
/// Enable them when switching to online/Firebase mode.
library;

export 'mock_repositories.dart';
export 'api_repositories.dart';
