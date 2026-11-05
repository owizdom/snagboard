import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/app_user.dart';
import 'incident.dart';
import 'incident_repository.dart';
import 'photo_store.dart';

/// Cloud Firestore implementation over the `incidents` collection.
/// Writes follow the exact field lists the security rules check.
class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository({required this.photos, FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final PhotoStore photos;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  @override
  Stream<List<Incident>> watchAll() => _incidents
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map(
        (snap) => [for (final d in snap.docs) Incident.fromMap(d.id, d.data())],
      );

  @override
  Future<String> create(
    IncidentDraft draft,
    AppUser reporter, {
    void Function(double progress)? onProgress,
  }) async {
    final doc = _incidents.doc();

    // Photo first, so the snag never points at a file that does not exist.
    String? photoUrl;
    String? photoPath;
    if (draft.photoPath != null) {
      final up = await photos.upload(
        reporter.uid,
        draft.photoPath!,
        onProgress: onProgress,
      );
      photoUrl = up.url;
      photoPath = up.path;
    }

    final spot = draft.spot?.trim();
    try {
      await doc.set({
        'title': draft.title.trim(),
        'description': draft.description.trim(),
        'category': draft.category!.name,
        'location': draft.location!,
        'spot': (spot == null || spot.isEmpty) ? null : spot,
        'urgency': draft.urgency.name,
        'status': IncidentStatus.submitted.wire,
        'photoUrl': photoUrl,
        'photoPath': photoPath,
        'reporterId': reporter.uid,
        'reporterName': draft.anonymous ? null : reporter.displayName,
        'anonymous': draft.anonymous,
        'affectedBy': <String>[],
        'history': [
          {
            'status': IncidentStatus.submitted.wire,
            'note': 'Filed',
            'byName': 'Reporter', // never the name: hiding it later must not leak
            'at': Timestamp.now(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Do not leave an orphan photo behind.
      if (photoPath != null) {
        try {
          await photos.delete(photoPath);
        } catch (_) {}
      }
      rethrow;
    }
    return doc.id;
  }

  @override
  Future<void> updateDetails(String id, IncidentDraft draft) async {
    final doc = _incidents.doc(id);
    final current = (await doc.get()).data() ?? const <String, dynamic>{};
    final wasAnonymous = (current['anonymous'] ?? false) as bool;

    // Name shown to others: null when anonymous, else the stored name, or
    // the user's profile name when anonymity was just switched off.
    String? reporterName;
    if (!draft.anonymous) {
      reporterName = current['reporterName'] as String?;
      if (wasAnonymous || reporterName == null) {
        final user = await _db
            .collection('users')
            .doc(current['reporterId'] as String)
            .get();
        reporterName = user.data()?['displayName'] as String?;
      }
    }

    final spot = draft.spot?.trim();
    await doc.update({
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'category': draft.category!.name,
      'location': draft.location!,
      'spot': (spot == null || spot.isEmpty) ? null : spot,
      'urgency': draft.urgency.name,
      'anonymous': draft.anonymous,
      'reporterName': reporterName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> changeStatus(
    Incident incident,
    IncidentStatus to,
    String note,
    AppUser staff,
  ) {
    // Write the whole list so earlier entries stay byte-identical.
    final history = [
      for (final h in incident.history) h.toMap(),
      {
        'status': to.wire,
        'note': note,
        'byName': staff.displayName,
        'at': Timestamp.now(),
      },
    ];
    return _incidents.doc(incident.id).update({
      'status': to.wire,
      'history': history,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setAffected(String id, String uid, bool affected) =>
      _incidents.doc(id).update({
        'affectedBy': affected
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
      });

  @override
  Future<void> delete(Incident incident, {required String callerUid}) async {
    await _incidents.doc(incident.id).delete();
    if (incident.photoPath != null && incident.reporterId == callerUid) {
      try {
        await photos.delete(incident.photoPath!);
      } catch (_) {
        // A missing or already-deleted photo must not fail the delete.
      }
    }
  }
}
