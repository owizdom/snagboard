import 'app_user.dart';

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

  /// Creates the account, writes `users/{uid}` with role student, and sends
  /// the verification email.
  Future<void> signUp(String name, String email, String password);

  Future<void> sendVerificationEmail();

  /// Reloads the user and returns whether the email is now verified.
  Future<bool> reloadVerified();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
