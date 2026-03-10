/// Domain layer — pure business logic with no framework dependencies.
///
/// ```
/// domain/
/// ├── entities/      Core data classes (Challenge, Team, Session, LeaderboardEntry)
/// ├── repositories/  Abstract repository contracts (interfaces)
/// └── usecases/      Business logic operations (DifficultyEngine, StartSession)
/// ```
library;

export 'entities/entities.dart';
export 'repositories/repositories.dart';
export 'usecases/usecases.dart';
