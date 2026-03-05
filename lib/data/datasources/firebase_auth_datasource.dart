import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_paths.dart';
import '../models/team_model.dart';

/// Firebase Authentication & Team Data Source
class FirebaseAuthDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Register a new team using anonymous auth + Firestore doc
  Future<TeamModel> registerTeam({
    required String teamName,
    required List<String> members,
  }) async {
    // Anonymous sign in to get a UID
    final credential = await _auth.signInAnonymously();
    final uid = credential.user!.uid;

    final team = TeamModel(
      id: uid,
      teamName: teamName,
      members: members,
      createdAt: DateTime.now(),
    );

    // Store team in Firestore
    await _firestore
        .collection(FirebasePaths.teams)
        .doc(uid)
        .set(team.toFirestore());

    return team;
  }

  /// Login with team ID — re-authenticates and fetches team doc
  Future<TeamModel> loginTeam(String teamId) async {
    final doc = await _firestore
        .collection(FirebasePaths.teams)
        .doc(teamId)
        .get();

    if (!doc.exists) {
      throw Exception('Team not found with ID: $teamId');
    }

    // Sign in anonymously if not already
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    return TeamModel.fromFirestore(doc);
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Stream of current team data
  Stream<TeamModel?> teamStream(String teamId) {
    return _firestore
        .collection(FirebasePaths.teams)
        .doc(teamId)
        .snapshots()
        .map((doc) => doc.exists ? TeamModel.fromFirestore(doc) : null);
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

