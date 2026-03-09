/// Data layer — models, datasources, repository implementations, and seed data.
///
/// ```
/// data/
/// ├── datasources/    Firebase auth, Firestore, and Realtime DB connectors
/// ├── models/         Serializable model classes (toJson / fromJson)
/// ├── repositories/   Concrete repository implementations (mock + Firebase)
/// └── seed/           Sample data for development and testing
/// ```
///
/// Note: Firebase datasources are excluded from this barrel because their
/// packages are disabled in pubspec.yaml (offline mode). Import them directly
/// when switching to online/Firebase mode.
library;

export 'models/models.dart';
export 'repositories/repositories_impl.dart';
export 'seed/sample_challenges.dart';
