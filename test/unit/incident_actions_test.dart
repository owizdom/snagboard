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
}
