import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/profile_screen.dart';

import '../fakes/fakes.dart';

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<TestHarness> open(
  WidgetTester t,
  AppUser user, {
  List<Incident> incidents = const [],
}) async {
  tall(t);
  final h = TestHarness.signedInAs(user, incidents: incidents);
  await t.pumpWidget(h.wrap(const ProfileScreen()));
  await t.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('student profile shows name, programme, role stamp, avatar', (
    t,
  ) async {
    await open(t, student);
    expect(find.text('Amani Student'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(K.programme),
        matching: find.textContaining('BSc Software Engineering'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(K.roleStamp), findsOneWidget);
    expect(find.byKey(K.avatar), findsOneWidget);
  });

  testWidgets('edit saves name and programme', (t) async {
    final h = await open(t, student);
    await t.tap(find.byKey(K.editProfile));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(K.editName), 'Amani K');
    await t.tap(find.byKey(K.editProgramme));
    await t.pumpAndSettle();
    await t.tap(
      find.byKey(K.programmeOption('BSc Entrepreneurial Leadership')).last,
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(K.editSave));
    await t.pumpAndSettle();
    expect(
      h.profiles.calls,
      contains('update:stu1:Amani K:BSc Entrepreneurial Leadership'),
    );
  });

  testWidgets('change photo goes through the repository', (t) async {
    final h = await open(t, student);
    await t.tap(find.byKey(K.editProfile));
    await t.pumpAndSettle();
    await t.tap(find.byKey(K.editPhoto));
    await t.pumpAndSettle();
    expect(h.profiles.calls, contains('setPhoto:stu1'));
  });
}
