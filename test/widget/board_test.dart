import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/board_screen.dart';

import '../fakes/fakes.dart';

List<Incident> sample() => [
  makeIncident(
    id: 'aaaa0001',
    title: 'Leaking tap in residence',
    category: IncidentCategory.water,
    createdAt: DateTime(2026, 11, 3),
  ),
  makeIncident(
    id: 'bbbb0002',
    title: 'Dead socket in the lab',
    category: IncidentCategory.electricity,
    location: 'Innovation Lab',
    createdAt: DateTime(2026, 11, 2),
  ),
  makeIncident(
    id: 'cccc0003',
    title: 'Fence gap at the sports ground',
    category: IncidentCategory.safety,
    location: 'Sports Ground',
    status: IncidentStatus.resolved,
    createdAt: DateTime(2026, 11, 1),
  ),
];

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

Future<TestHarness> open(WidgetTester t, List<Incident> incidents) async {
  tall(t);
  final h = TestHarness.signedInAs(student, incidents: incidents);
  await t.pumpWidget(h.wrap(const BoardScreen()));
  await t.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('shows the empty state with no snags', (t) async {
    await open(t, const []);
    expect(find.byKey(K.listEmpty), findsOneWidget);
    expect(find.byKey(K.listError), findsNothing);
  });

  testWidgets('lists every snag as a ticket', (t) async {
    await open(t, sample());
    for (final id in ['aaaa0001', 'bbbb0002', 'cccc0003']) {
      expect(find.byKey(K.ticket(id)), findsOneWidget);
    }
    expect(find.byKey(K.listEmpty), findsNothing);
  });

  testWidgets('a category chip narrows the list', (t) async {
    await open(t, sample());
    await tapKey(t, K.categoryChip(IncidentCategory.water));
    expect(find.byKey(K.ticket('aaaa0001')), findsOneWidget);
    expect(find.byKey(K.ticket('bbbb0002')), findsNothing);
    expect(find.byKey(K.ticket('cccc0003')), findsNothing);
    // Tapping again clears the chip.
    await tapKey(t, K.categoryChip(IncidentCategory.water));
    expect(find.byKey(K.ticket('bbbb0002')), findsOneWidget);
  });
}
