import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/core/campus.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/file_snag_screen.dart';

import '../fakes/fakes.dart';

const goodTitle = 'Tap leaking badly';
const goodDesc = 'The tap in the corridor has been leaking since Monday.';
final place = campusLocations[1]; // Library

Incident openSnag() => makeIncident(
  id: 'zzzz9999',
  category: IncidentCategory.water,
  location: place,
  reporterId: 'stu2',
  reporterName: 'Kofi Student',
);

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
  WidgetTester t, {
  List<Incident> incidents = const [],
}) async {
  tall(t);
  final h = TestHarness.signedInAs(student, incidents: incidents);
  await t.pumpWidget(h.wrap(const FileSnagScreen()));
  await t.pumpAndSettle();
  return h;
}

Future<void> toStep2(WidgetTester t) async {
  await tapKey(t, K.categoryRow(IncidentCategory.water));
  await tapKey(t, K.next);
  await tapKey(t, K.locationOption(place));
  await tapKey(t, K.next);
}

Future<void> toReview(WidgetTester t) async {
  await toStep2(t);
  await t.enterText(find.byKey(K.title), goodTitle);
  await t.enterText(find.byKey(K.description), goodDesc);
  await tapKey(t, K.next);
}

void main() {
  testWidgets('step 0 blocks Next without a category and shows an error', (
    t,
  ) async {
    await open(t);
    expect(find.byKey(K.fieldError), findsNothing);
    await tapKey(t, K.next);
    expect(find.byKey(K.fieldError), findsOneWidget);
    expect(find.byKey(K.categoryRow(IncidentCategory.water)), findsOneWidget);
    expect(find.byKey(K.back), findsNothing, reason: 'still on the first step');
  });

  testWidgets('SAFETY shows the notice, other categories do not', (t) async {
    await open(t);
    expect(find.byKey(K.safetyNotice), findsNothing);
    await tapKey(t, K.categoryRow(IncidentCategory.safety));
    expect(find.byKey(K.safetyNotice), findsOneWidget);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    expect(find.byKey(K.safetyNotice), findsNothing);
  });

  testWidgets('submit calls create once with the draft', (t) async {
    final h = await open(t);
    await toReview(t);
    await tapKey(t, K.submit);
    expect(h.incidents.calls, ['create']);
    expect(h.incidents.lastDraft!.title, goodTitle);
    expect(h.incidents.lastDraft!.description, goodDesc);
    expect(h.incidents.lastDraft!.category, IncidentCategory.water);
    expect(h.incidents.lastDraft!.location, place);
  });
}
