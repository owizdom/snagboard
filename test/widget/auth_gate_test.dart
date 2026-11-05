import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/app_user.dart';
import 'package:snagboard/auth/auth_providers.dart';
import 'package:snagboard/core/theme.dart';
import 'package:snagboard/incidents/incident_providers.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/auth_gate.dart';
import 'package:snagboard/ui/screens/sign_in_screen.dart';
import 'package:snagboard/ui/screens/verify_email_screen.dart';

import '../fakes/fakes.dart';

/// A repository whose session stream never emits: the gate stays loading.
class NeverAuth extends FakeAuthRepository {
  @override
  Stream<AuthSession?> sessionChanges() =>
      StreamController<AuthSession?>().stream;
}

AuthSession verified(AppUser u) =>
    AuthSession(uid: u.uid, email: u.email, emailVerified: true);

void main() {
  testWidgets('signed out shows the sign in screen', (tester) async {
    final h = TestHarness();
    await tester.pumpWidget(h.wrap(const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byKey(K.tabBoard), findsNothing);
  });

  testWidgets('signed in but unverified shows verify email', (tester) async {
    final h = TestHarness(
      session: AuthSession(
        uid: 'stu1',
        email: student.email,
        emailVerified: false,
      ),
    );
    await tester.pumpWidget(h.wrap(const AuthGate()));
    // The verify screen may run a resend timer, so settle by pumping.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byKey(K.tabBoard), findsNothing);
  });

  testWidgets('verified student gets BOARD, MINE and ME, no QUEUE', (
    tester,
  ) async {
    final h = TestHarness.signedInAs(student);
    await tester.pumpWidget(h.wrap(const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byKey(K.tabBoard), findsOneWidget);
    expect(find.byKey(K.tabMine), findsOneWidget);
    expect(find.byKey(K.tabMe), findsOneWidget);
    expect(find.byKey(K.tabQueue), findsNothing);
  });

  testWidgets('verified staff gets QUEUE, BOARD and ME, no MINE', (
    tester,
  ) async {
    final h = TestHarness.signedInAs(staff);
    await tester.pumpWidget(h.wrap(const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byKey(K.tabQueue), findsOneWidget);
    expect(find.byKey(K.tabBoard), findsOneWidget);
    expect(find.byKey(K.tabMe), findsOneWidget);
    expect(find.byKey(K.tabMine), findsNothing);
  });

  testWidgets('shows loading until the session stream emits', (tester) async {
    final h = TestHarness();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(NeverAuth()),
          profileRepositoryProvider.overrideWithValue(h.profiles),
          incidentRepositoryProvider.overrideWithValue(h.incidents),
        ],
        retry: (_, _) => null,
        child: MaterialApp(theme: buildSnagTheme(), home: const AuthGate()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(K.gateLoading), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byKey(K.tabBoard), findsNothing);
  });

  testWidgets('a session stream error shows an error panel with retry', (
    tester,
  ) async {
    final h = TestHarness();
    h.auth.sessionError = Exception('no network');
    await tester.pumpWidget(h.wrap(const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byKey(K.gateError), findsOneWidget);
    expect(find.byKey(K.gateRetry), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  // Regression: an account without a profile must not be a dead end.
  testWidgets('a verified account with no profile can sign out from the error', (
    tester,
  ) async {
    final h = TestHarness(
      session: const AuthSession(
        uid: 'ghost',
        email: 'ghost@alustudent.com',
        emailVerified: true,
      ),
    );
    await tester.pumpWidget(h.wrap(const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byKey(K.gateError), findsOneWidget);
    await tester.tap(find.byKey(K.gateSignOut));
    await tester.pumpAndSettle();
    expect(h.auth.calls, contains('signOut'));
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
