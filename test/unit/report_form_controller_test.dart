import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/auth_providers.dart';
import 'package:snagboard/core/validators.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/report_form_controller.dart';

import '../fakes/fakes.dart';

const goodTitle = 'Tap leaking badly';
const goodDesc = 'The tap in the corridor has been leaking since Monday.';

Future<void> ready(ProviderContainer c) async {
  c.listen(currentUserProvider, (_, _) {});
  c.listen(reportFormProvider, (_, _) {});
  await c.read(sessionProvider.future);
  await c.pump();
  await c.read(currentUserProvider.future);
  await Future<void>.delayed(Duration.zero);
  expect(c.read(currentUserProvider).value?.uid, 'stu1', reason: 'test setup');
}

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late ReportFormController f;

  ReportFormState st() => c.read(reportFormProvider);

  Future<void> setUpWith({List<Incident> incidents = const []}) async {
    h = TestHarness.signedInAs(student, incidents: incidents);
    c = h.container();
    addTearDown(c.dispose);
    await ready(c);
    f = c.read(reportFormProvider.notifier);
  }

  void fillStep0And1() {
    f.setCategory(IncidentCategory.water);
    expect(f.next(), isTrue);
    f.setLocation('Library');
    expect(f.next(), isTrue);
  }

  void fillStep2() {
    f.setTitle(goodTitle);
    f.setDescription(goodDesc);
    expect(f.next(), isTrue);
  }

  test('starts on step 0 with an empty draft', () async {
    await setUpWith();
    expect(st().step, 0);
    expect(st().draft.category, isNull);
    expect(st().submitting, isFalse);
  });

  test('step 0 refuses to advance without a category', () async {
    await setUpWith();
    expect(f.next(), isFalse);
    expect(st().step, 0);
    expect(st().errors.containsKey('category'), isTrue);
  });

  test('setting a field clears that field error', () async {
    await setUpWith();
    f.next();
    f.setCategory(IncidentCategory.safety);
    expect(st().errors.containsKey('category'), isFalse);
    expect(st().draft.category, IncidentCategory.safety);
  });

  test('step 1 needs a location', () async {
    await setUpWith();
    f.setCategory(IncidentCategory.water);
    expect(f.next(), isTrue);
    expect(st().step, 1);
    expect(f.next(), isFalse);
    expect(st().step, 1);
    expect(st().errors.containsKey('location'), isTrue);
    f.setLocation('Library');
    expect(st().errors.containsKey('location'), isFalse);
    expect(f.next(), isTrue);
    expect(st().step, 2);
  });

  test('step 2 reports validator messages for title and description', () async {
    await setUpWith();
    f.setCategory(IncidentCategory.water);
    f.next();
    f.setLocation('Library');
    f.next();
    f.setTitle('abc');
    f.setDescription('short');
    expect(f.next(), isFalse);
    expect(st().step, 2);
    expect(st().errors['title'], validateTitle('abc'));
    expect(st().errors['description'], validateDescription('short'));
    f.setTitle(goodTitle);
    expect(st().errors.containsKey('title'), isFalse);
    expect(st().errors.containsKey('description'), isTrue);
    f.setDescription(goodDesc);
    expect(f.next(), isTrue);
    expect(st().step, 3);
  });

  test('back goes one step and never below 0', () async {
    await setUpWith();
    f.setCategory(IncidentCategory.water);
    f.next();
    expect(st().step, 1);
    f.back();
    expect(st().step, 0);
    f.back();
    expect(st().step, 0);
  });

  test('draft setters store their values', () async {
    await setUpWith();
    f.setUrgency(Urgency.urgent);
    f.setSpot('Room 12');
    f.setAnonymous(true);
    f.setPhoto('/tmp/a.jpg');
    expect(st().draft.urgency, Urgency.urgent);
    expect(st().draft.spot, 'Room 12');
    expect(st().draft.anonymous, isTrue);
    expect(st().draft.photoPath, '/tmp/a.jpg');
    f.setPhoto(null);
    expect(st().draft.photoPath, isNull);
  });

  test('submit calls create once with the draft and records the id', () async {
    await setUpWith();
    fillStep0And1();
    fillStep2();
    await f.submit();
    expect(h.incidents.calls, ['create']);
    expect(h.incidents.lastDraft!.title, goodTitle);
    expect(h.incidents.lastDraft!.category, IncidentCategory.water);
    expect(h.incidents.lastDraft!.location, 'Library');
    expect(st().done, isTrue);
    expect(st().error, isNull);
    expect(st().submitting, isFalse);
    expect(h.incidents.items.first.id, st().createdId);
    expect(h.incidents.items.first.reporterId, 'stu1');
  });

  test(
    'failed submit keeps the draft, sets error, and retry succeeds',
    () async {
      await setUpWith();
      fillStep0And1();
      fillStep2();
      h.incidents.failNext = Exception('offline');
      await f.submit();
      expect(h.incidents.calls, ['create']);
      expect(st().error, isNotNull);
      expect(st().done, isFalse);
      expect(st().submitting, isFalse);
      expect(st().draft.title, goodTitle);
      expect(st().step, 3);
      await f.submit();
      expect(h.incidents.calls, ['create', 'create']);
      expect(st().error, isNull);
      expect(st().done, isTrue);
    },
  );

  test('startEdit loads the snag and submit calls updateDetails', () async {
    final existing = makeIncident(id: 'abcd1234', reporterId: 'stu1');
    await setUpWith(incidents: [existing]);
    f.startEdit(existing);
    expect(st().isEditing, isTrue);
    expect(st().editingId, 'abcd1234');
    expect(st().draft.title, existing.title);
    f.setTitle('Tap leaking even worse');
    await f.submit();
    expect(h.incidents.calls, ['updateDetails:abcd1234']);
    expect(h.incidents.lastDraft!.title, 'Tap leaking even worse');
    expect(st().done, isTrue);
  });
}
