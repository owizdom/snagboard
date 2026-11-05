import '../auth/app_user.dart';

abstract class ProfileRepository {
  /// The profile at `users/{uid}`, or null while it does not exist yet.
  Stream<AppUser?> watch(String uid);

  Future<void> create(AppUser user);
}
