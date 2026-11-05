import '../auth/app_user.dart';
import 'incident.dart';

/// Every read and write of snags goes through this interface. The app uses
/// the Firestore implementation; tests use an in-memory fake.
abstract class IncidentRepository {
  /// All snags, newest first, at most 200. Emits again on every change.
  Stream<List<Incident>> watchAll();

  /// Uploads the draft's photo (if any), then writes the snag with status
  /// submitted and one history entry. Returns the new id.
  Future<String> create(
    IncidentDraft draft,
    AppUser reporter, {
    void Function(double progress)? onProgress,
  });

  /// Owner only, while the snag is still submitted.
  Future<void> updateDetails(String id, IncidentDraft draft);

  /// Staff only. Sets the status and appends one history entry with [note].
  Future<void> changeStatus(
    Incident incident,
    IncidentStatus to,
    String note,
    AppUser staff,
  );

  /// Adds or removes [uid] from `affectedBy`.
  Future<void> setAffected(String id, String uid, bool affected);

  /// Deletes the snag, and its photo when the caller owns it.
  Future<void> delete(Incident incident, {required String callerUid});
}
