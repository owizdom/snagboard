import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  }) => _doc(uid).update({
    'displayName': displayName.trim(),
    'programme': programme,
  });

  @override
  Future<void> setPhoto(String uid, String localPath) async {
    // 1. Upload the new file.
    final newPath = 'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(newPath);
    await ref.putFile(File(localPath), SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    // 2. Remember the old file, then point the profile at the new one.
    final snap = await _doc(uid).get();
    final oldPath = snap.data()?['photoPath'] as String?;
    await _doc(uid).update({'photoUrl': url, 'photoPath': newPath});

    // 3. Delete the old file; it may already be gone.
    if (oldPath != null) {
      try {
        await FirebaseStorage.instance.ref(oldPath).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }
  }
}
