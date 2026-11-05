import '../auth/app_user.dart';
import 'profile_repository.dart';

/// Reads and writes `users/{uid}` in Cloud Firestore.
class FirestoreProfileRepository implements ProfileRepository {
  @override
  Stream<AppUser?> watch(String uid) => throw UnimplementedError();
  @override
  Future<void> create(AppUser user) => throw UnimplementedError();
}
