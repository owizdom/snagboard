/// Where snag photos live (Firebase Storage in the app, memory in tests).
abstract class PhotoStore {
  /// Uploads to `incident_photos/{uid}/{timestamp}.jpg`.
  Future<({String url, String path})> upload(
    String uid,
    String localPath, {
    void Function(double progress)? onProgress,
  });

  Future<void> delete(String path);
}

/// Picks a photo and returns its local path, or null when cancelled.
abstract class PhotoPicker {
  Future<String?> pick({required bool fromCamera});
}
