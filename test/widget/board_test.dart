import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/auth_providers.dart';
import 'package:snagboard/core/theme.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_providers.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/board_screen.dart';

import '../fakes/fakes.dart';

class NeverIncidents extends FakeIncidentRepository {
  @override
  Stream<List<Incident>> watchAll() =>
      StreamController<List<Incident>>().stream;
}

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
  testWidgets('shows loading before the first snapshot', (t) async {
    tall(t);
    final h = TestHarness.signedInAs(student);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(h.auth),
          profileRepositoryProvider.overrideWithValue(h.profiles),
          incidentRepositoryProvider.overrideWithValue(NeverIncidents()),
          photoStoreProvider.overrideWithValue(h.photos),
        ],
        retry: (_, _) => null,
        child: MaterialApp(theme: buildSnagTheme(), home: const BoardScreen()),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(K.listLoading), findsOneWidget);
    expect(find.byKey(K.listEmpty), findsNothing);
    expect(find.byKey(K.listError), findsNothing);
  });

  testWidgets('shows error with retry when the stream fails', (t) async {
    tall(t);
    final h = TestHarness.signedInAs(student);
    h.incidents.watchError = Exception('permission denied');
    await t.pumpWidget(h.wrap(const BoardScreen()));
    await t.pumpAndSettle();
    expect(find.byKey(K.listError), findsOneWidget);
    expect(find.byKey(K.listRetry), findsOneWidget);
    expect(find.byKey(K.listLoading), findsNothing);
  });

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

  testWidgets('a ribbon segment narrows the list', (t) async {
    await open(t, sample());
    await tapKey(t, K.ribbonSegment(StatusGroup.closed));
    expect(find.byKey(K.ticket('cccc0003')), findsOneWidget);
    expect(find.byKey(K.ticket('aaaa0001')), findsNothing);
    expect(find.byKey(K.ticket('bbbb0002')), findsNothing);
    await tapKey(t, K.ribbonSegment(StatusGroup.open));
    expect(find.byKey(K.ticket('aaaa0001')), findsOneWidget);
    expect(find.byKey(K.ticket('bbbb0002')), findsOneWidget);
    expect(find.byKey(K.ticket('cccc0003')), findsNothing);
  });

  testWidgets('the search box narrows the list, case-insensitively', (t) async {
    await open(t, sample());
    await t.enterText(find.byKey(K.search), 'SOCKET');
    await t.pumpAndSettle();
    expect(find.byKey(K.ticket('bbbb0002')), findsOneWidget);
    expect(find.byKey(K.ticket('aaaa0001')), findsNothing);
    expect(find.byKey(K.ticket('cccc0003')), findsNothing);
    await t.enterText(find.byKey(K.search), '');
    await t.pumpAndSettle();
    expect(find.byKey(K.ticket('aaaa0001')), findsOneWidget);
  });
}
