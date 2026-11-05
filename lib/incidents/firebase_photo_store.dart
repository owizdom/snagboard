import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'photo_store.dart';

/// Firebase Storage implementation. Paths: incident_photos/{uid}/{ms}.jpg,
/// contentType image/jpeg.
class FirebasePhotoStore implements PhotoStore {
  @override
  Future<({String url, String path})> upload(
    String uid,
    String localPath, {
    void Function(double progress)? onProgress,
  }) async {
    final path =
        'incident_photos/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(path);
    final task = ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return (url: await ref.getDownloadURL(), path: path);
  }

  @override
  Future<void> delete(String path) async {
    try {
      await FirebaseStorage.instance.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

/// image_picker implementation, resized to 1600 px wide at quality 80.
class ImagePickerPhotoPicker implements PhotoPicker {
  @override
  Future<String?> pick({required bool fromCamera}) async {
    final file = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    return file?.path;
  }
}
