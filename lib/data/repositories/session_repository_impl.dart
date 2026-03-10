import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_paths.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/realtime_db_datasource.dart';
import '../models/session_model.dart';

/// Firebase implementation of SessionRepository
class SessionRepositoryImpl implements SessionRepository {
  final FirestoreDatasource _firestore;
  final RealtimeDbDatasource _realtimeDb;

  SessionRepositoryImpl(this._firestore, this._realtimeDb);

  @override
  Future<Session> createSession(String teamId) async {
    final now = DateTime.now();
    final endTime = now.add(const Duration(hours: 2));

    final session = SessionModel(
      id: '', // Will be set by Firestore
      teamId: teamId,
      startTime: now,
      endTime: endTime,
    );

    final docRef = await _firestore
        .collection(FirebasePaths.sessions)
        .add(session.toFirestore());

    // Also write timer to Realtime DB for server-side tracking
    await _realtimeDb.setData(
      '${FirebasePaths.activeTimers}/$teamId',
      {
        'sessionId': docRef.id,
        'startTime': now.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'isActive': true,
      },
    );

    // Update team with session ID
    await _firestore.updateDoc(
      FirebasePaths.teams,
      teamId,
      {'sessionId': docRef.id},
    );

    return SessionModel(
      id: docRef.id,
      teamId: teamId,
      startTime: now,
      endTime: endTime,
    );
  }

  @override
  Future<Session?> getActiveSession(String teamId) async {
    final snapshot = await _firestore
        .collection(FirebasePaths.sessions)
        .where('teamId', isEqualTo: teamId)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SessionModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Stream<Session?> sessionStream(String teamId) {
    return _firestore
        .collection(FirebasePaths.sessions)
        .where('teamId', isEqualTo: teamId)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SessionModel.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _firestore.updateDoc(
      FirebasePaths.sessions,
      sessionId,
      {'isActive': false},
    );
  }

  @override
  Future<void> updateSession(Session session) async {
    final model = SessionModel.fromEntity(session);
    await _firestore.setDoc(
      FirebasePaths.sessions,
      session.id,
      model.toFirestore(),
      merge: true,
    );
  }

  @override
  Future<void> checkAndEndExpiredSession(String sessionId) async {
    final doc = await _firestore.getDoc(FirebasePaths.sessions, sessionId);
    if (!doc.exists) return;

    final session = SessionModel.fromFirestore(doc);
    if (session.isExpired && session.isActive) {
      await endSession(sessionId);
      // Clean up realtime DB timer
      await _realtimeDb
          .removeData('${FirebasePaths.activeTimers}/${session.teamId}');
    }
  }
}

