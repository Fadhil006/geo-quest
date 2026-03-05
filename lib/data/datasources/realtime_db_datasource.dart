import 'package:firebase_database/firebase_database.dart';

/// Realtime Database Data Source for leaderboard and live data
class RealtimeDbDatasource {
  final FirebaseDatabase _database;

  RealtimeDbDatasource({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  /// Get a database reference
  DatabaseReference ref(String path) {
    return _database.ref(path);
  }

  /// Set data at a path
  Future<void> setData(String path, Map<String, dynamic> data) {
    return _database.ref(path).set(data);
  }

  /// Update data at a path
  Future<void> updateData(String path, Map<String, dynamic> data) {
    return _database.ref(path).update(data);
  }

  /// Remove data at a path
  Future<void> removeData(String path) {
    return _database.ref(path).remove();
  }

  /// Stream data at a path
  Stream<DatabaseEvent> streamData(String path) {
    return _database.ref(path).onValue;
  }

  /// Stream ordered by child, limited
  Stream<DatabaseEvent> streamOrdered(
    String path, {
    required String orderByChild,
    int? limitToLast,
  }) {
    Query query = _database.ref(path).orderByChild(orderByChild);
    if (limitToLast != null) {
      query = query.limitToLast(limitToLast);
    }
    return query.onValue;
  }

  /// Get server timestamp
  static Map<String, String> get serverTimestamp => ServerValue.timestamp;
}

