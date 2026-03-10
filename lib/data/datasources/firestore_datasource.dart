import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore CRUD helper
class FirestoreDatasource {
  final FirebaseFirestore _firestore;

  FirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseFirestore get instance => _firestore;

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
      String collection, String docId) {
    return _firestore.collection(collection).doc(docId).get();
  }

  /// Set a document
  Future<void> setDoc(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return _firestore
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  /// Update a document
  Future<void> updateDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    return _firestore.collection(collection).doc(docId).update(data);
  }

  /// Delete a document
  Future<void> deleteDoc(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).delete();
  }

  /// Query documents
  Future<QuerySnapshot<Map<String, dynamic>>> query(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = query.where(filter.field, isEqualTo: filter.isEqualTo);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.get();
  }

  /// Stream a document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(
      String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// Stream a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collection, {
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    return query.snapshots();
  }

  /// Server timestamp helper
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}

class QueryFilter {
  final String field;
  final dynamic isEqualTo;

  QueryFilter({required this.field, this.isEqualTo});
}

