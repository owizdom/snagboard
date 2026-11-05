import '../auth/app_user.dart';
import 'incident.dart';
import 'incident_repository.dart';
import 'photo_store.dart';

/// Cloud Firestore implementation over the `incidents` collection.
class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository({required this.photos});
  final PhotoStore photos;

  @override
  Stream<List<Incident>> watchAll() => throw UnimplementedError();
  @override
  Future<String> create(IncidentDraft draft, AppUser reporter,
          {void Function(double progress)? onProgress}) =>
      throw UnimplementedError();
  @override
  Future<void> updateDetails(String id, IncidentDraft draft) =>
      throw UnimplementedError();
  @override
  Future<void> changeStatus(
          Incident incident, IncidentStatus to, String note, AppUser staff) =>
      throw UnimplementedError();
  @override
  Future<void> setAffected(String id, String uid, bool affected) =>
      throw UnimplementedError();
  @override
  Future<void> delete(Incident incident, {required String callerUid}) =>
      throw UnimplementedError();
}
