import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/app_user.dart';
import 'profile_repository.dart';

/// Reads and writes `users/{uid}` in Cloud Firestore.
class FirestoreProfileRepository implements ProfileRepository {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  Stream<AppUser?> watch(String uid) => _doc(uid).snapshots().map((snap) {
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return AppUser.fromMap(uid, data);
  });

  @override
  Future<void> create(AppUser user) =>
      _doc(user.uid)
          .set({...user.toMap(), 'createdAt': FieldValue.serverTimestamp()});

  @override
  Future<void> update(
    String uid, {
    required String displayName,
    String? programme,
  }) => throw UnimplementedError();

  @override
  Future<void> setPhoto(String uid, String localPath) =>
      throw UnimplementedError();
}
