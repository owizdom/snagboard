import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/auth_gate.dart';
import 'package:snagboard/ui/screens/sign_in_screen.dart';
import 'package:snagboard/ui/screens/verify_email_screen.dart';

import '../fakes/fakes.dart';

TestHarness unverified() => TestHarness(
  session: AuthSession(uid: 'stu1', email: student.email, emailVerified: false),
);

/// The screen may run a timer, so never pumpAndSettle here.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

int count(TestHarness h, String call) =>
    h.auth.calls.where((c) => c == call).length;

void main() {
  testWidgets('check while still unverified re-checks and stays', (t) async {
    final h = unverified()..auth.verifiedOnReload = false;
    await t.pumpWidget(h.wrap(const AuthGate()));
    await settle(t);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await t.tap(find.byKey(K.verifyCheck));
    await settle(t);
    expect(count(h, 'reload'), 1);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.byKey(K.tabBoard), findsNothing);
  });

  testWidgets('check once verified moves on to the app', (t) async {
    final h = unverified()..auth.verifiedOnReload = true;
    await t.pumpWidget(h.wrap(const AuthGate()));
    await settle(t);
    await t.tap(find.byKey(K.verifyCheck));
    await settle(t);
    expect(count(h, 'reload'), 1);
    expect(find.byType(VerifyEmailScreen), findsNothing);
    expect(find.byKey(K.tabBoard), findsOneWidget);
  });

  testWidgets('resend is blocked for 60 seconds after a send', (t) async {
    final h = unverified();
    await t.pumpWidget(h.wrap(const AuthGate()));
    await settle(t);
    // Let any cooldown from an automatic first send expire.
    await t.pump(const Duration(seconds: 61));
    expect(count(h, 'resend'), lessThanOrEqualTo(1));
    final before = count(h, 'resend');

    await t.tap(find.byKey(K.verifyResend));
    await settle(t);
    expect(count(h, 'resend'), before + 1, reason: 'enabled after cooldown');

    // Immediately after a send the button does nothing.
    await t.tap(find.byKey(K.verifyResend), warnIfMissed: false);
    await settle(t);
    expect(
      count(h, 'resend'),
      before + 1,
      reason: 'disabled right after a send',
    );

    await t.pump(const Duration(seconds: 30));
    await t.tap(find.byKey(K.verifyResend), warnIfMissed: false);
    await settle(t);
    expect(count(h, 'resend'), before + 1, reason: 'still disabled at 30 s');

    await t.pump(const Duration(seconds: 31));
    await t.tap(find.byKey(K.verifyResend));
    await settle(t);
    expect(count(h, 'resend'), before + 2, reason: 'enabled after 61 s');
  });

  testWidgets('use another account signs out and shows sign in', (t) async {
    final h = unverified();
    await t.pumpWidget(h.wrap(const AuthGate()));
    await settle(t);
    await t.tap(find.byKey(K.verifyUseAnother));
    await settle(t);
    expect(h.auth.calls, contains('signOut'));
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });
}
