import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/auth_providers.dart';
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

  test('step 0 refuses to advance without a category', () async {
    await setUpWith();
    expect(f.next(), isFalse);
    expect(st().step, 0);
    expect(st().errors.containsKey('category'), isTrue);
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
}
