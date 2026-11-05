import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/core/campus.dart';
import 'package:snagboard/core/validators.dart';
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

  testWidgets('choosing a category lets Next advance to WHERE', (t) async {
    await open(t);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    await tapKey(t, K.next);
    expect(find.byKey(K.fieldError), findsNothing);
    expect(find.byKey(K.locationOption(place)), findsOneWidget);
    expect(find.byKey(K.categoryRow(IncidentCategory.water)), findsNothing);
  });

  testWidgets('SAFETY shows the notice, other categories do not', (t) async {
    await open(t);
    expect(find.byKey(K.safetyNotice), findsNothing);
    await tapKey(t, K.categoryRow(IncidentCategory.safety));
    expect(find.byKey(K.safetyNotice), findsOneWidget);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    expect(find.byKey(K.safetyNotice), findsNothing);
  });

  testWidgets('step 1 blocks Next without a location', (t) async {
    await open(t);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    await tapKey(t, K.next);
    await tapKey(t, K.next);
    expect(find.byKey(K.fieldError), findsOneWidget);
    expect(find.byKey(K.locationOption(place)), findsOneWidget);
  });

  testWidgets('similar open snags appear with an affects-me-too action', (
    t,
  ) async {
    final h = await open(t, incidents: [openSnag()]);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    await tapKey(t, K.next);
    expect(find.byKey(K.similarList), findsNothing);
    await tapKey(t, K.locationOption(place));
    expect(find.byKey(K.similarList), findsOneWidget);
    expect(find.byKey(K.similarAffects('zzzz9999')), findsOneWidget);
    await tapKey(t, K.similarAffects('zzzz9999'));
    expect(h.incidents.calls, ['setAffected:zzzz9999:stu1:true']);
  });

  testWidgets('no similar list for a different location', (t) async {
    await open(t, incidents: [openSnag()]);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    await tapKey(t, K.next);
    await tapKey(t, K.locationOption(campusLocations.last));
    expect(find.byKey(K.similarList), findsNothing);
  });

  testWidgets('a resolved snag is not offered as similar', (t) async {
    await open(
      t,
      incidents: [openSnag().copyWith(status: IncidentStatus.resolved)],
    );
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    await tapKey(t, K.next);
    await tapKey(t, K.locationOption(place));
    expect(find.byKey(K.similarList), findsNothing);
  });

  testWidgets('step 2 shows validator messages for empty fields', (t) async {
    await open(t);
    await toStep2(t);
    await tapKey(t, K.next);
    expect(find.text(validateTitle('')!), findsWidgets);
    expect(find.text(validateDescription('')!), findsWidgets);
  });

  testWidgets('step 2 shows messages for too-short input then advances', (
    t,
  ) async {
    await open(t);
    await toStep2(t);
    await t.enterText(find.byKey(K.title), 'abc');
    await t.enterText(find.byKey(K.description), 'short');
    await tapKey(t, K.next);
    expect(find.text(validateTitle('abc')!), findsWidgets);
    expect(find.text(validateDescription('short')!), findsWidgets);
    await t.enterText(find.byKey(K.title), goodTitle);
    await t.enterText(find.byKey(K.description), goodDesc);
    await tapKey(t, K.next);
    expect(find.byKey(K.submit), findsOneWidget);
  });

  testWidgets('review shows the draft', (t) async {
    await open(t);
    await toReview(t);
    expect(find.text(goodTitle), findsWidgets);
    expect(find.byKey(K.submit), findsOneWidget);
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

  testWidgets('failed submit shows retry, keeps the draft, retry succeeds', (
    t,
  ) async {
    final h = await open(t);
    await toReview(t);
    h.incidents.failNext = Exception('offline');
    await tapKey(t, K.submit);
    expect(h.incidents.calls, ['create']);
    expect(find.byKey(K.submitRetry), findsOneWidget);
    expect(find.text(goodTitle), findsWidgets, reason: 'draft kept');
    await tapKey(t, K.submitRetry);
    expect(h.incidents.calls, ['create', 'create']);
    expect(h.incidents.lastDraft!.title, goodTitle);
    expect(find.byKey(K.submitRetry), findsNothing);
  });
}
