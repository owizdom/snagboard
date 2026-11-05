// AT15: the whole product on the Auth, Firestore and Storage emulators.
// Run through tool/e2e.sh; refuses to run against real Firebase.
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snagboard/app.dart';
import 'package:snagboard/core/campus.dart';
import 'package:snagboard/firebase_options.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_providers.dart';
import 'package:snagboard/incidents/photo_store.dart';
import 'package:snagboard/main.dart' show useEmulators;
import 'package:snagboard/ui/keys.dart';

import 'emulator_admin.dart';

/// An 8x8 JPEG.
const _jpegBase64 =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAIAAgDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDBooor5w/QD//Z';

const _password = 'E2eTest2026pass';

class _FilePicker implements PhotoPicker {
  _FilePicker(this.path);
  final String path;
  @override
  Future<String?> pick({required bool fromCamera}) async => path;
}

/// Pumps in 200 ms steps for [duration]. Firestore streams and progress
/// spinners never "settle", so tests never call pumpAndSettle.
Future<void> pumpFor(
  WidgetTester t, [
  Duration duration = const Duration(milliseconds: 600),
]) async {
  final end = DateTime.now().add(duration);
  do {
    await t.pump(const Duration(milliseconds: 200));
  } while (DateTime.now().isBefore(end));
}

Future<void> pumpUntilFound(
  WidgetTester t,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .join(' | ');
      throw TestFailure('timed out after $timeout waiting for $finder. '
          'Visible text: $texts');
    }
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<void> tapKey(WidgetTester t, Key key) async {
  await pumpUntilFound(t, find.byKey(key));
  await t.ensureVisible(find.byKey(key));
  await t.pump(const Duration(milliseconds: 100));
  await t.tap(find.byKey(key));
  await pumpFor(t);
}

Future<void> enter(WidgetTester t, Key key, String text) async {
  await pumpUntilFound(t, find.byKey(key));
  await t.ensureVisible(find.byKey(key));
  await t.pump(const Duration(milliseconds: 100));
  await t.enterText(find.byKey(key), text);
  await t.pump(const Duration(milliseconds: 100));
}

/// Joined text of the widget with [key] (the Text itself or its descendants).
String textOf(WidgetTester t, Key key) {
  final finder = find.byKey(key);
  final w = t.widget(finder.first);
  if (w is Text) return w.data ?? w.textSpan?.toPlainText() ?? '';
  return t
      .widgetList<Text>(
        find.descendant(of: finder.first, matching: find.byType(Text)),
      )
      .map((x) => x.data ?? x.textSpan?.toPlainText() ?? '')
      .join(' ');
}

Future<void> pumpUntilTextOf(
  WidgetTester t,
  Key key,
  bool Function(String) test, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (true) {
    if (find.byKey(key).evaluate().isNotEmpty && test(textOf(t, key))) return;
    if (DateTime.now().isAfter(end)) {
      final now = find.byKey(key).evaluate().isEmpty
          ? '<no widget>'
          : textOf(t, key);
      throw TestFailure('timed out waiting on text of $key, last: "$now"');
    }
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<void> signUp(WidgetTester t, String name, String email) async {
  await tapKey(t, K.signInToSignUp);
  await enter(t, K.signUpName, name);
  await enter(t, K.signUpEmail, email);
  await enter(t, K.signUpPassword, _password);
  await enter(t, K.signUpConfirm, _password);
  await tapKey(t, K.signUpSubmit);
  await pumpUntilFound(t, find.byKey(K.verifyCheck));
}

Future<void> signOut(WidgetTester t) async {
  await tapKey(t, K.tabMe);
  await tapKey(t, K.signOut);
  await pumpUntilFound(t, find.byKey(K.signInEmail));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AT15 student files, staff moves it, student sees it', (t) async {
    expect(
      useEmulators,
      isTrue,
      reason: 'refusing to run against real Firebase; use tool/e2e.sh',
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    await FirebaseAuth.instance.signOut();

    final tmp = await Directory.systemTemp.createTemp('snagboard_e2e');
    addTearDown(() => tmp.delete(recursive: true));
    final photo = File('${tmp.path}/leak.jpg')
      ..writeAsBytesSync(base64Decode(_jpegBase64));

    final ts = DateTime.now().millisecondsSinceEpoch;
    final studentEmail = 'e2e.student+$ts@alustudent.com';
    final staffEmail = 'e2e.staff+$ts@alueducation.com';
    final title = 'E2E leaking tap $ts';
    const description =
        'The tap in the corridor has been leaking since Monday.';
    const note = 'Plumber assigned, fixing it today';
    final place = campusLocations[1];

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          photoPickerProvider.overrideWithValue(_FilePicker(photo.path)),
        ],
        child: const SnagboardApp(),
      ),
    );
    await pumpUntilFound(t, find.byKey(K.signInEmail));

    // 1. Student signs up and lands on the verify screen.
    await signUp(t, 'E2E Student', studentEmail);
    expect(find.byKey(K.verifyCheck), findsOneWidget);

    // 2. Verified through the Auth emulator, then the student shell opens.
    await markEmailVerified(studentEmail);
    await tapKey(t, K.verifyCheck);
    await pumpUntilFound(t, find.byKey(K.tabBoard));
    expect(find.byKey(K.tabMine), findsOneWidget);
    expect(
      find.byKey(K.tabQueue),
      findsNothing,
      reason: 'student has no queue',
    );

    // 3. File a snag through all four steps with a photo.
    await tapKey(t, K.fileSnag);
    await tapKey(t, K.categoryRow(IncidentCategory.water));
    await tapKey(t, K.next);
    await tapKey(t, K.locationOption(place));
    await tapKey(t, K.next);
    await enter(t, K.title, title);
    await enter(t, K.description, description);
    await tapKey(t, K.addPhoto);
    await pumpUntilFound(t, find.byKey(K.removePhoto));
    await tapKey(t, K.next);
    await pumpUntilFound(t, find.byKey(K.submit));
    await tapKey(t, K.submit);
    await pumpUntilFound(
      t,
      find.byKey(K.tabBoard),
      timeout: const Duration(seconds: 40),
    );
    await pumpUntilFound(t, find.text(title));
    expect(find.text(title), findsWidgets);

    final objects = await storageObjects('incident_photos/');
    expect(objects, hasLength(1), reason: 'one photo uploaded: $objects');
    final snagId = await incidentIdByTitle(title);
    expect(snagId, isNotNull, reason: 'incident document exists in Firestore');

    // 4. Staff account.
    await signOut(t);
    await signUp(t, 'E2E Staff', staffEmail);
    final staffUid = await markEmailVerified(staffEmail);
    await waitForUserDoc(staffUid);
    await setRole(staffUid, 'staff');
    await tapKey(t, K.verifyCheck);
    await pumpUntilFound(t, find.byKey(K.tabQueue));

    // 5. Staff moves the snag to IN PROGRESS with a note.
    await pumpUntilFound(t, find.text(title));
    await t.ensureVisible(find.text(title).first);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text(title).first);
    await pumpFor(t);
    await tapKey(t, K.moveTo(IncidentStatus.inProgress));
    await enter(t, K.statusNote, note);
    await tapKey(t, K.confirmMove);
    await pumpUntilTextOf(
      t,
      K.detailStamp,
      (s) => s.toLowerCase().contains(
        IncidentStatus.inProgress.label.toLowerCase(),
      ),
    );

    // 6. Student signs back in and sees the new stamp and the note.
    await signOut(t);
    await enter(t, K.signInEmail, studentEmail);
    await enter(t, K.signInPassword, _password);
    await tapKey(t, K.signInSubmit);
    await pumpUntilFound(t, find.byKey(K.tabMine));
    await tapKey(t, K.tabMine);
    await pumpUntilFound(t, find.byKey(K.ticket(snagId!)));
    await pumpUntilTextOf(
      t,
      K.ticketStamp(snagId),
      (s) => s.toLowerCase().contains(
        IncidentStatus.inProgress.label.toLowerCase(),
      ),
    );
    await t.ensureVisible(find.byKey(K.ticket(snagId)));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(K.ticket(snagId)));
    await pumpFor(t);
    await pumpUntilFound(t, find.byKey(K.detailTrack));
    await pumpUntilFound(
      t,
      find.descendant(
        of: find.byKey(K.detailTrack),
        matching: find.textContaining(note),
      ),
    );
  });
}
