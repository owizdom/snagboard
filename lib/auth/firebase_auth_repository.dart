import '../auth/app_user.dart';
import 'auth_repository.dart';

/// Firebase Auth implementation. signUp also writes `users/{uid}` (role
/// student) through Firestore and sends the verification email. Firebase
/// error codes map to readable [AuthFailure] messages.
class FirebaseAuthRepository implements AuthRepository {
  @override
  Stream<AuthSession?> sessionChanges() => throw UnimplementedError();
  @override
  Future<void> signIn(String email, String password) => throw UnimplementedError();
  @override
  Future<void> signUp(String name, String email, String password) =>
      throw UnimplementedError();
  @override
  Future<void> sendVerificationEmail() => throw UnimplementedError();
  @override
  Future<bool> reloadVerified() => throw UnimplementedError();
  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();
  @override
  Future<void> signOut() => throw UnimplementedError();
}
