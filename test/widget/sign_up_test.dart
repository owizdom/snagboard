import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/core/validators.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/sign_up_screen.dart';

import '../fakes/fakes.dart';

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> fill(
  WidgetTester t, {
  String name = 'Amani Student',
  String email = 'amani@alustudent.com',
  String password = 'Passw0rdOK',
  String confirm = 'Passw0rdOK',
}) async {
  await t.enterText(find.byKey(K.signUpName), name);
  await t.enterText(find.byKey(K.signUpEmail), email);
  await t.enterText(find.byKey(K.signUpPassword), password);
  await t.enterText(find.byKey(K.signUpConfirm), confirm);
}

Future<void> submit(WidgetTester t) async {
  await t.ensureVisible(find.byKey(K.signUpSubmit));
  await t.tap(find.byKey(K.signUpSubmit));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('non-ALU email shows its message and does not call signUp', (
    t,
  ) async {
    tall(t);
    final h = TestHarness();
    await t.pumpWidget(h.wrap(const SignUpScreen()));
    await fill(t, email: 'a@gmail.com');
    await submit(t);
    expect(find.text(validateAluEmail('a@gmail.com')!), findsWidgets);
    expect(h.auth.calls, isEmpty);
  });

  testWidgets('valid form calls signUp exactly once', (t) async {
    tall(t);
    final h = TestHarness();
    await t.pumpWidget(h.wrap(const SignUpScreen()));
    await fill(t);
    await submit(t);
    expect(
      h.auth.calls.where((c) => c == 'signUp:amani@alustudent.com'),
      hasLength(1),
    );
    expect(h.auth.calls.where((c) => c.startsWith('signUp')), hasLength(1));
  });
}
