import 'photo_store.dart';

/// Firebase Storage implementation. Paths: incident_photos/{uid}/{ms}.jpg,
/// contentType image/jpeg.
class FirebasePhotoStore implements PhotoStore {
  @override
  Future<({String url, String path})> upload(String uid, String localPath,
          {void Function(double progress)? onProgress}) =>
      throw UnimplementedError();
  @override
  Future<void> delete(String path) => throw UnimplementedError();
}

/// image_picker implementation, resized to 1600 px wide at quality 80.
class ImagePickerPhotoPicker implements PhotoPicker {
  @override
  Future<String?> pick({required bool fromCamera}) => throw UnimplementedError();
}
