import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/core/validators.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/incident_detail_screen.dart';

import '../fakes/fakes.dart';

const expectedNext = <IncidentStatus, Set<IncidentStatus>>{
  IncidentStatus.submitted: {
    IncidentStatus.acknowledged,
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  },
  IncidentStatus.acknowledged: {
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  },
  IncidentStatus.inProgress: {IncidentStatus.resolved},
  IncidentStatus.resolved: {IncidentStatus.inProgress},
  IncidentStatus.declined: {IncidentStatus.acknowledged},
};

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> tapKey(WidgetTester t, Key key) async {
  await t.ensureVisible(find.byKey(key));
  await t.pump();
  await t.tap(find.byKey(key));
  await t.pumpAndSettle();
}

Future<TestHarness> open(
  WidgetTester t,
  AppUser user,
  Incident incident,
) async {
  tall(t);
  final h = TestHarness.signedInAs(user, incidents: [incident]);
  await t.pumpWidget(h.wrap(IncidentDetailScreen(incidentId: incident.id)));
  await t.pumpAndSettle();
  return h;
}

void main() {
  group('staff', () {
    for (final status in IncidentStatus.values) {
      testWidgets('from ${status.name} sees Move to only for allowed targets', (
        t,
      ) async {
        await open(t, staff, makeIncident(status: status));
        for (final to in IncidentStatus.values) {
          expect(
            find.byKey(K.moveTo(to)),
            expectedNext[status]!.contains(to) ? findsOneWidget : findsNothing,
            reason: '${status.name} -> ${to.name}',
          );
        }
      });
    }

    testWidgets('confirming with an empty note does not change status', (
      t,
    ) async {
      final h = await open(t, staff, makeIncident());
      await tapKey(t, K.moveTo(IncidentStatus.inProgress));
      await tapKey(t, K.confirmMove);
      expect(h.incidents.calls, isEmpty);
      expect(find.text(validateNote('')!), findsWidgets);
    });

    testWidgets('a too-short note does not change status', (t) async {
      final h = await open(t, staff, makeIncident());
      await tapKey(t, K.moveTo(IncidentStatus.inProgress));
      await t.enterText(find.byKey(K.statusNote), 'ok');
      await tapKey(t, K.confirmMove);
      expect(h.incidents.calls, isEmpty);
      expect(find.text(validateNote('ok')!), findsWidgets);
    });

    testWidgets('a valid note changes the status', (t) async {
      final h = await open(t, staff, makeIncident(id: 'abcd1234'));
      await tapKey(t, K.moveTo(IncidentStatus.inProgress));
      await t.enterText(find.byKey(K.statusNote), 'Plumber assigned');
      await tapKey(t, K.confirmMove);
      expect(h.incidents.calls, ['changeStatus:abcd1234:in_progress']);
    });

    testWidgets('does not see owner-only actions on a snag they did not file', (
      t,
    ) async {
      await open(t, staff, makeIncident());
      expect(find.byKey(K.edit), findsNothing);
      expect(find.byKey(K.withdraw), findsNothing);
    });
  });

  group('students', () {
    for (final user in [student, otherStudent]) {
      testWidgets('${user.uid} never sees a Move to action', (t) async {
        for (final status in IncidentStatus.values) {
          await open(t, user, makeIncident(status: status));
          for (final to in IncidentStatus.values) {
            expect(find.byKey(K.moveTo(to)), findsNothing);
          }
        }
      });
    }

    testWidgets('owner sees Edit and Withdraw while submitted', (t) async {
      await open(t, student, makeIncident(status: IncidentStatus.submitted));
      expect(find.byKey(K.edit), findsOneWidget);
      expect(find.byKey(K.withdraw), findsOneWidget);
    });

    for (final s in IncidentStatus.values.where(
      (s) => s != IncidentStatus.submitted,
    )) {
      testWidgets('owner does not see Edit or Withdraw when ${s.name}', (
        t,
      ) async {
        await open(t, student, makeIncident(status: s));
        expect(find.byKey(K.edit), findsNothing);
        expect(find.byKey(K.withdraw), findsNothing);
      });
    }

    testWidgets('owner does not see the affects toggle', (t) async {
      await open(t, student, makeIncident(reporterId: 'stu1'));
      expect(find.byKey(K.affectsToggle), findsNothing);
    });

    testWidgets('non-owner sees affects toggle and no owner actions', (
      t,
    ) async {
      await open(t, otherStudent, makeIncident(reporterId: 'stu1'));
      expect(find.byKey(K.affectsToggle), findsOneWidget);
      expect(find.byKey(K.edit), findsNothing);
      expect(find.byKey(K.withdraw), findsNothing);
    });

    testWidgets('tapping affects toggle calls setAffected', (t) async {
      final h = await open(
        t,
        otherStudent,
        makeIncident(id: 'abcd1234', reporterId: 'stu1'),
      );
      await tapKey(t, K.affectsToggle);
      expect(h.incidents.calls, ['setAffected:abcd1234:stu2:true']);
    });

    testWidgets('tapping again removes the affect', (t) async {
      final h = await open(
        t,
        otherStudent,
        makeIncident(id: 'abcd1234', reporterId: 'stu1', affectedBy: ['stu2']),
      );
      await tapKey(t, K.affectsToggle);
      expect(h.incidents.calls, ['setAffected:abcd1234:stu2:false']);
    });
  });
}
