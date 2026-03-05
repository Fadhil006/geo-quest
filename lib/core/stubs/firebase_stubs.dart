/// Stub for firebase_core when Firebase packages are not installed.
/// This file is only used in offline mode.
///
/// When you install Firebase (via `flutterfire configure`), uncomment the
/// Firebase dependencies in pubspec.yaml and these stubs will be unused.

class Firebase {
  static Future<void> initializeApp() async {}
}

