import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/incident_detail_screen.dart';

import '../fakes/fakes.dart';

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
  testWidgets('staff see Move to for the allowed next statuses', (t) async {
    await open(t, staff, makeIncident(status: IncidentStatus.submitted));
    expect(find.byKey(K.moveTo(IncidentStatus.acknowledged)), findsOneWidget);
    expect(find.byKey(K.moveTo(IncidentStatus.resolved)), findsNothing);
  });

  testWidgets('students never see Move to', (t) async {
    await open(t, student, makeIncident());
    for (final to in IncidentStatus.values) {
      expect(find.byKey(K.moveTo(to)), findsNothing);
    }
  });

  testWidgets('a valid note changes the status', (t) async {
    final h = await open(t, staff, makeIncident(id: 'abcd1234'));
    await tapKey(t, K.moveTo(IncidentStatus.inProgress));
    await t.enterText(find.byKey(K.statusNote), 'Plumber assigned');
    await tapKey(t, K.confirmMove);
    expect(h.incidents.calls, ['changeStatus:abcd1234:in_progress']);
  });

  testWidgets('the owner sees Edit and Withdraw only while submitted', (
    t,
  ) async {
    await open(t, student, makeIncident(status: IncidentStatus.submitted));
    expect(find.byKey(K.edit), findsOneWidget);
    expect(find.byKey(K.withdraw), findsOneWidget);
    await open(t, student, makeIncident(status: IncidentStatus.acknowledged));
    expect(find.byKey(K.edit), findsNothing);
    expect(find.byKey(K.withdraw), findsNothing);
  });

  testWidgets('staff see the name of a reporter who hid it', (t) async {
    await open(t, staff, makeIncident(anonymous: true));
    expect(find.textContaining('Amani Student'), findsWidgets);
  });
}
