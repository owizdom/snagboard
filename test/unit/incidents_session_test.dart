import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_providers.dart';

import '../fakes/fakes.dart';

void main() {
  test(
    'the snag listener restarts for the next user after a refused one',
    () async {
      final h = TestHarness.signedInAs(staff);
      final c = h.container();
      addTearDown(c.dispose);

      c.listen(incidentsProvider, (_, _) {});
      await pumpEventQueue();

      // Firestore refuses the open listener once the user signs out.
      h.incidents.refuseOpenListeners(Exception('permission-denied'));
      await pumpEventQueue();
      expect(c.read(incidentsProvider), isA<AsyncError<List<Incident>>>());

      await h.auth.signOut();
      await pumpEventQueue();
      h.auth.emit(
        AuthSession(
          uid: student.uid,
          email: student.email,
          emailVerified: true,
        ),
      );
      await pumpEventQueue();

      expect(c.read(incidentsProvider), isA<AsyncData<List<Incident>>>());
    },
  );
}
