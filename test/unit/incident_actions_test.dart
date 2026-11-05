import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/auth/auth_providers.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_actions.dart';

import '../fakes/fakes.dart';

Future<ProviderContainer> signedIn(TestHarness h, AppUser u) async {
  final c = h.container();
  addTearDown(c.dispose);
  c.listen(currentUserProvider, (_, _) {});
  c.listen(incidentActionsProvider, (_, _) {});
  await c.read(sessionProvider.future);
  await c.pump();
  await c.read(currentUserProvider.future);
  await Future<void>.delayed(Duration.zero);
  expect(c.read(currentUserProvider).value?.uid, u.uid, reason: 'test setup');
  return c;
}

void main() {
  group('changeStatus', () {
    test(
      'staff with a valid transition and note calls the repository',
      () async {
        final i = makeIncident();
        final h = TestHarness.signedInAs(staff, incidents: [i]);
        final c = await signedIn(h, staff);
        await c
            .read(incidentActionsProvider.notifier)
            .changeStatus(i, IncidentStatus.inProgress, 'Plumber assigned');
        expect(h.incidents.calls, ['changeStatus:abcd1234:in_progress']);
        expect(h.incidents.items.single.status, IncidentStatus.inProgress);
        expect(h.incidents.items.single.history.last.note, 'Plumber assigned');
        expect(h.incidents.items.single.history.last.byName, staff.displayName);
      },
    );

    test('invalid transition throws StateError and does not write', () async {
      final i = makeIncident(status: IncidentStatus.submitted);
      final h = TestHarness.signedInAs(staff, incidents: [i]);
      final c = await signedIn(h, staff);
      await expectLater(
        c
            .read(incidentActionsProvider.notifier)
            .changeStatus(i, IncidentStatus.resolved, 'Skipping ahead'),
        throwsStateError,
      );
      expect(h.incidents.calls, isEmpty);
    });

    test('invalid note throws StateError and does not write', () async {
      final i = makeIncident();
      final h = TestHarness.signedInAs(staff, incidents: [i]);
      final c = await signedIn(h, staff);
      await expectLater(
        c
            .read(incidentActionsProvider.notifier)
            .changeStatus(i, IncidentStatus.acknowledged, ''),
        throwsStateError,
      );
      expect(h.incidents.calls, isEmpty);
    });
  });

  group('toggleAffected', () {
    test('adds the current user when not yet affected', () async {
      final i = makeIncident(reporterId: 'stu1');
      final h = TestHarness.signedInAs(otherStudent, incidents: [i]);
      final c = await signedIn(h, otherStudent);
      await c.read(incidentActionsProvider.notifier).toggleAffected(i);
      expect(h.incidents.calls, ['setAffected:abcd1234:stu2:true']);
    });

    test('removes the current user when already affected', () async {
      final i = makeIncident(reporterId: 'stu1', affectedBy: ['stu2']);
      final h = TestHarness.signedInAs(otherStudent, incidents: [i]);
      final c = await signedIn(h, otherStudent);
      await c.read(incidentActionsProvider.notifier).toggleAffected(i);
      expect(h.incidents.calls, ['setAffected:abcd1234:stu2:false']);
    });
  });

  group('delete', () {
    test('delegates to the repository', () async {
      final i = makeIncident(reporterId: 'stu1');
      final h = TestHarness.signedInAs(student, incidents: [i]);
      final c = await signedIn(h, student);
      await c.read(incidentActionsProvider.notifier).delete(i);
      expect(h.incidents.calls, ['delete:abcd1234']);
      expect(h.incidents.items, isEmpty);
    });
  });

  test('a failing write surfaces as error state', () async {
    final i = makeIncident(reporterId: 'stu1');
    final h = TestHarness.signedInAs(student, incidents: [i]);
    final c = await signedIn(h, student);
    h.incidents.failNext = Exception('boom');
    try {
      await c.read(incidentActionsProvider.notifier).delete(i);
    } catch (_) {}
    expect(h.incidents.calls, ['delete:abcd1234']);
    expect(c.read(incidentActionsProvider).hasError, isTrue);
  });
}
