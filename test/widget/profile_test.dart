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

  testWidgets('summary counts and recent snags', (t) async {
    await open(
      t,
      student,
      incidents: [
        makeIncident(
          id: 'aaaa0001',
          status: IncidentStatus.submitted,
          createdAt: DateTime(2026, 11, 3),
        ),
        makeIncident(
          id: 'bbbb0002',
          status: IncidentStatus.inProgress,
          createdAt: DateTime(2026, 11, 2),
        ),
        makeIncident(
          id: 'cccc0003',
          status: IncidentStatus.resolved,
          createdAt: DateTime(2026, 11, 1),
        ),
        makeIncident(
          id: 'dddd0004',
          reporterId: 'stu2',
          createdAt: DateTime(2026, 11, 4),
        ),
      ],
    );
    void count(String name, String n) => expect(
      find.descendant(
        of: find.byKey(K.summary(name)),
        matching: find.text(n),
      ),
      findsOneWidget,
      reason: name,
    );
    count('total', '3');
    count('open', '1');
    count('active', '1');
    count('resolved', '1');
    expect(
      find.descendant(
        of: find.byKey(K.recentList),
        matching: find.byKey(K.ticket('aaaa0001')),
      ),
      findsOneWidget,
    );
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

  testWidgets('staff are offered departments, not degrees', (t) async {
    await open(t, staff);
    await t.tap(find.byKey(K.editProfile));
    await t.pumpAndSettle();
    await t.tap(find.byKey(K.editProgramme));
    await t.pumpAndSettle();
    expect(find.byKey(K.programmeOption('Facilities')), findsWidgets);
    expect(
      find.byKey(K.programmeOption('BSc Software Engineering')),
      findsNothing,
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
