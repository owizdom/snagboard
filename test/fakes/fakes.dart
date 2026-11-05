import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/auth/auth_providers.dart';
import 'package:snagboard/auth/auth_repository.dart';
import 'package:snagboard/core/theme.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_providers.dart';
import 'package:snagboard/incidents/incident_repository.dart';
import 'package:snagboard/incidents/photo_store.dart';
import 'package:snagboard/profile/profile_repository.dart';

/// A stream that replays the latest value to every new listener.
class _Latest<T> {
  _Latest(this.value);
  T value;
  final _ctrl = StreamController<T>.broadcast();
  Object? pendingError;

  Stream<T> get stream async* {
    if (pendingError != null) throw pendingError!;
    yield value;
    yield* _ctrl.stream;
  }

  void set(T v) {
    value = v;
    _ctrl.add(v);
  }

  void error(Object e) => _ctrl.addError(e);
}

const student = AppUser(
  uid: 'stu1',
  email: 'amani@alustudent.com',
  displayName: 'Amani Student',
  role: UserRole.student,
);
const otherStudent = AppUser(
  uid: 'stu2',
  email: 'kofi@alustudent.com',
  displayName: 'Kofi Student',
  role: UserRole.student,
);
const staff = AppUser(
  uid: 'staff1',
  email: 'facilities@alueducation.com',
  displayName: 'Facilities Desk',
  role: UserRole.staff,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? session}) : _session = _Latest(session);
  final _Latest<AuthSession?> _session;

  /// Every call, e.g. 'signIn:a@alustudent.com', 'signUp:...', 'resend'.
  final calls = <String>[];

  /// When set, the next call throws this and the field is cleared.
  Object? failNext;

  /// What [reloadVerified] reports.
  bool verifiedOnReload = false;

  /// Makes [sessionChanges] fail for the next listener.
  set sessionError(Object e) => _session.pendingError = e;

  void emit(AuthSession? s) => _session.set(s);

  void _maybeFail() {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  @override
  Stream<AuthSession?> sessionChanges() => _session.stream;

  @override
  Future<void> signIn(String email, String password) async {
    calls.add('signIn:$email');
    _maybeFail();
    _session.set(AuthSession(uid: 'stu1', email: email, emailVerified: true));
  }

  @override
  Future<void> signUp(String name, String email, String password) async {
    calls.add('signUp:$email');
    _maybeFail();
    _session.set(AuthSession(uid: 'new1', email: email, emailVerified: false));
  }

  @override
  Future<void> sendVerificationEmail() async {
    calls.add('resend');
    _maybeFail();
  }

  @override
  Future<bool> reloadVerified() async {
    calls.add('reload');
    _maybeFail();
    if (verifiedOnReload) {
      final s = _session.value;
      if (s != null) {
        _session.set(
          AuthSession(uid: s.uid, email: s.email, emailVerified: true),
        );
      }
    }
    return verifiedOnReload;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    _maybeFail();
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _maybeFail();
    _session.set(null);
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([Iterable<AppUser> users = const []]) {
    for (final u in users) {
      _users[u.uid] = u;
    }
  }
  final _users = <String, AppUser>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<AppUser?> watch(String uid) async* {
    yield _users[uid];
    await for (final _ in _changes.stream) {
      yield _users[uid];
    }
  }

  @override
  Future<void> create(AppUser user) async {
    _users[user.uid] = user;
    _changes.add(null);
  }
}

class FakePhotoStore implements PhotoStore {
  final uploads = <String>[];
  final deletes = <String>[];

  @override
  Future<({String url, String path})> upload(
    String uid,
    String localPath, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    onProgress?.call(1);
    uploads.add(localPath);
    final path = 'incident_photos/$uid/${uploads.length}.jpg';
    return (url: 'https://example.test/$path', path: path);
  }

  @override
  Future<void> delete(String path) async => deletes.add(path);
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.result = '/tmp/fake_photo.jpg']);
  String? result;

  @override
  Future<String?> pick({required bool fromCamera}) async => result;
}

/// In-memory snags. Records calls; [failNext] makes the next write throw.
class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository([List<Incident> initial = const []])
    : _items = _Latest(List.of(initial));
  final _Latest<List<Incident>> _items;
  final calls = <String>[];
  Object? failNext;
  IncidentDraft? lastDraft;
  int _seq = 0;

  /// Makes [watchAll] fail for the next listener.
  set watchError(Object e) => _items.pendingError = e;

  List<Incident> get items => _items.value;

  /// Pushes a replacement snag through the stream, as Firestore would.
  void push(Incident updated) => _items.set([
    for (final i in _items.value) i.id == updated.id ? updated : i,
  ]);

  void _maybeFail() {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  @override
  Stream<List<Incident>> watchAll() => _items.stream;

  @override
  Future<String> create(
    IncidentDraft draft,
    AppUser reporter, {
    void Function(double progress)? onProgress,
  }) async {
    calls.add('create');
    lastDraft = draft;
    _maybeFail();
    onProgress?.call(1);
    final id = 'new${++_seq}abcd';
    final now = DateTime.now();
    _items.set([
      Incident(
        id: id,
        title: draft.title,
        description: draft.description,
        category: draft.category ?? IncidentCategory.other,
        location: draft.location ?? '',
        spot: draft.spot,
        urgency: draft.urgency,
        status: IncidentStatus.submitted,
        reporterId: reporter.uid,
        reporterName: draft.anonymous ? null : reporter.displayName,
        anonymous: draft.anonymous,
        history: [
          StatusChange(
            status: IncidentStatus.submitted,
            note: 'Filed',
            byName: draft.anonymous ? 'Reporter' : reporter.displayName,
            at: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      ..._items.value,
    ]);
    return id;
  }

  @override
  Future<void> updateDetails(String id, IncidentDraft draft) async {
    calls.add('updateDetails:$id');
    lastDraft = draft;
    _maybeFail();
    final i = _items.value.firstWhere((e) => e.id == id);
    push(i.copyWith(title: draft.title, description: draft.description));
  }

  @override
  Future<void> changeStatus(
    Incident incident,
    IncidentStatus to,
    String note,
    AppUser staff,
  ) async {
    calls.add('changeStatus:${incident.id}:${to.wire}');
    _maybeFail();
    final i = _items.value.firstWhere((e) => e.id == incident.id);
    push(
      i.copyWith(
        status: to,
        history: [
          ...i.history,
          StatusChange(
            status: to,
            note: note,
            byName: staff.displayName,
            at: DateTime.now(),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> setAffected(String id, String uid, bool affected) async {
    calls.add('setAffected:$id:$uid:$affected');
    _maybeFail();
    final i = _items.value.firstWhere((e) => e.id == id);
    final next = {...i.affectedBy};
    affected ? next.add(uid) : next.remove(uid);
    push(i.copyWith(affectedBy: next.toList()));
  }

  @override
  Future<void> delete(Incident incident, {required String callerUid}) async {
    calls.add('delete:${incident.id}');
    _maybeFail();
    _items.set(_items.value.where((e) => e.id != incident.id).toList());
  }
}

/// A snag with sensible defaults; override what the test cares about.
Incident makeIncident({
  String id = 'abcd1234',
  String title = 'No water on floor 2',
  String description = 'Taps on the second floor have been dry since morning.',
  IncidentCategory category = IncidentCategory.water,
  String location = 'Student Residence A',
  String? spot = 'Floor 2',
  Urgency urgency = Urgency.normal,
  IncidentStatus status = IncidentStatus.submitted,
  String reporterId = 'stu1',
  String? reporterName = 'Amani Student',
  bool anonymous = false,
  List<String> affectedBy = const [],
  List<StatusChange>? history,
  DateTime? createdAt,
  String? photoUrl,
  String? photoPath,
}) {
  final at = createdAt ?? DateTime(2026, 11, 1, 9);
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    spot: spot,
    urgency: urgency,
    photoUrl: photoUrl,
    photoPath: photoPath,
    status: status,
    reporterId: reporterId,
    reporterName: anonymous ? null : reporterName,
    anonymous: anonymous,
    affectedBy: affectedBy,
    history:
        history ??
        [
          StatusChange(
            status: IncidentStatus.submitted,
            note: 'Filed',
            byName: 'Amani Student',
            at: at,
          ),
        ],
    createdAt: at,
    updatedAt: at,
  );
}

/// Everything a widget test needs, wired to fakes.
class TestHarness {
  TestHarness({
    AuthSession? session,
    List<AppUser> users = const [student, otherStudent, staff],
    List<Incident> incidents = const [],
  }) : auth = FakeAuthRepository(session: session),
       profiles = FakeProfileRepository(users),
       incidents = FakeIncidentRepository(incidents);

  /// Signed in and verified as [user].
  factory TestHarness.signedInAs(
    AppUser user, {
    List<Incident> incidents = const [],
  }) => TestHarness(
    session: AuthSession(uid: user.uid, email: user.email, emailVerified: true),
    incidents: incidents,
  );

  final FakeAuthRepository auth;
  final FakeProfileRepository profiles;
  final FakeIncidentRepository incidents;
  final photos = FakePhotoStore();
  final picker = FakePhotoPicker();

  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
    incidentRepositoryProvider.overrideWithValue(incidents),
    photoStoreProvider.overrideWithValue(photos),
    photoPickerProvider.overrideWithValue(picker),
  ];

  ProviderContainer container() =>
      ProviderContainer(overrides: overrides, retry: (_, __) => null);

  /// Wraps [child] in the app theme with fakes and no automatic retries.
  Widget wrap(Widget child) => ProviderScope(
    overrides: overrides,
    retry: (_, __) => null,
    child: MaterialApp(theme: buildSnagTheme(), home: child),
  );
}
