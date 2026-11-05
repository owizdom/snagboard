import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/auth_gate.dart';
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
}
