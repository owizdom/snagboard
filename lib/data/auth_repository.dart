import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:snagboard/data/models.dart';

/// Thrown by repositories with a message fit to show the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthRepository {
  /// Null when signed out. Emits on sign-in, sign-out and verification
  /// reloads.
  Stream<AuthSession?> sessionChanges();

  Future<void> signIn(String email, String password);

  /// Creates the account, writes `users/{uid}` (staff for @alueducation.com,
  /// student otherwise) and sends the verification email.
  Future<void> signUp(String name, String email, String password);

  Future<void> sendVerificationEmail();

  /// Reloads the user and returns whether the email is now verified.
  Future<bool> reloadVerified();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

/// Firebase Auth implementation. signUp also writes `users/{uid}` (role
/// student) through Firestore and sends the verification email. Firebase
/// error codes map to readable [AuthFailure] messages.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Stream<AuthSession?> sessionChanges() => _auth.userChanges().map((user) {
    if (user == null) return null;
    return AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
    );
  });

  @override
  Future<void> signIn(String email, String password) => _wrap(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<void> signUp(String name, String email, String password) =>
      _wrap(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user!;
        await user.updateDisplayName(name);
        // The profile document the rest of the app reads.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': name,
          'email': email.toLowerCase(),
          // ALU staff addresses start as staff; everyone else as student.
          'role': email.trim().toLowerCase().endsWith('@alueducation.com')
              ? 'staff'
              : 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await user.sendEmailVerification();
      });

  @override
  Future<void> sendVerificationEmail() => _wrap(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('You are signed out');
    await user.sendEmailVerification();
  });

  @override
  Future<bool> reloadVerified() => _wrap(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('You are signed out');
    // Refresh the ID token first: the security rules read email_verified
    // from the token, and reload() alone keeps the old, unverified one.
    // Doing it before reload() means the app only moves on once Firestore
    // will accept the verified user.
    await user.getIdToken(true);
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      _wrap(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _auth.signOut();

  /// Runs [action] and turns Firebase errors into [AuthFailure].
  Future<T> _wrap<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email or password is incorrect';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Choose a stronger password';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again';
      case 'invalid-email':
        return 'That email address is not valid';
      default:
        return 'Something went wrong. Please try again';
    }
  }
}

abstract class ProfileRepository {
  /// The profile at `users/{uid}`, or null while it does not exist yet.
  Stream<AppUser?> watch(String uid);

  /// Owner only: name and degree/department.
  Future<void> update(
    String uid, {
    required String displayName,
    String? programme,
  });

  /// Uploads to avatars/{uid}/{time}.jpg, saves photoUrl/photoPath, and
  /// deletes the previous photo.
  Future<void> setPhoto(String uid, String localPath);
}

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
  Future<void> update(
    String uid, {
    required String displayName,
    String? programme,
  }) =>
      _doc(uid)
          .update({'displayName': displayName.trim(), 'programme': programme});

  @override
  Future<void> setPhoto(String uid, String localPath) async {
    // 1. Upload the new file.
    final newPath = 'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(newPath);
    await ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
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
