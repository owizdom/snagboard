import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/auth_controller.dart';
import 'package:snagboard/auth/auth_repository.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late AuthController a;

  setUp(() {
    h = TestHarness();
    c = h.container();
    addTearDown(c.dispose);
    c.listen(authControllerProvider, (_, _) {});
    a = c.read(authControllerProvider.notifier);
  });

  test('signIn delegates to the repository', () async {
    await a.signIn('amani@alustudent.com', 'Passw0rdOK');
    expect(h.auth.calls, ['signIn:amani@alustudent.com']);
    expect(c.read(authControllerProvider).hasError, isFalse);
  });

  test('signUp delegates once', () async {
    await a.signUp('Amani', 'amani@alustudent.com', 'Passw0rdOK');
    expect(h.auth.calls, ['signUp:amani@alustudent.com']);
  });

  test('sendPasswordReset delegates', () async {
    await a.sendPasswordReset('amani@alustudent.com');
    expect(h.auth.calls, ['reset:amani@alustudent.com']);
  });

  test('resendVerification calls sendVerificationEmail', () async {
    await a.resendVerification();
    expect(h.auth.calls, ['resend']);
  });

  test('checkVerified returns false when not verified', () async {
    h.auth.verifiedOnReload = false;
    expect(await a.checkVerified(), isFalse);
    expect(h.auth.calls, ['reload']);
  });

  test('checkVerified returns true when verified', () async {
    h.auth.verifiedOnReload = true;
    expect(await a.checkVerified(), isTrue);
    expect(h.auth.calls, ['reload']);
  });

  test('signOut delegates', () async {
    await a.signOut();
    expect(h.auth.calls, ['signOut']);
  });

  test('a failed sign in puts the failure message into error state', () async {
    h.auth.failNext = const AuthFailure('Wrong password');
    try {
      await a.signIn('amani@alustudent.com', 'Passw0rdOK');
    } catch (_) {}
    expect(h.auth.calls, ['signIn:amani@alustudent.com']);
    final s = c.read(authControllerProvider);
    expect(s.hasError, isTrue);
    expect(s.error.toString(), contains('Wrong password'));
  });

  test('a later success clears the error', () async {
    h.auth.failNext = const AuthFailure('Wrong password');
    try {
      await a.signIn('amani@alustudent.com', 'Passw0rdOK');
    } catch (_) {}
    await a.signIn('amani@alustudent.com', 'Passw0rdOK');
    expect(c.read(authControllerProvider).hasError, isFalse);
  });
}
