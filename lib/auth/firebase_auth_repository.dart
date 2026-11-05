import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/app_user.dart';
import 'auth_repository.dart';

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
          'role': email.trim().toLowerCase().endsWith('@alueducation.com') ? 'staff' : 'student',
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
