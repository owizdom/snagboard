import '../auth/app_user.dart';

abstract class ProfileRepository {
  /// The profile at `users/{uid}`, or null while it does not exist yet.
  Stream<AppUser?> watch(String uid);

  Future<void> create(AppUser user);

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
