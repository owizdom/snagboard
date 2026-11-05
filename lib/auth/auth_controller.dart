import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Runs auth actions and exposes their progress as AsyncValue: loading
/// while a call runs, error with the message to show, data when done.
/// Every method delegates to `authRepositoryProvider`.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  String _clean(String email) => email.trim().toLowerCase();

  /// Marks the state as loading, runs [action], and stores its outcome.
  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }

  Future<void> signIn(String email, String password) => _run(
    () => ref.read(authRepositoryProvider).signIn(_clean(email), password),
  );

  Future<void> signUp(String name, String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUp(name.trim(), _clean(email), password),
  );

  Future<void> sendPasswordReset(String email) => _run(
    () => ref.read(authRepositoryProvider).sendPasswordReset(_clean(email)),
  );

  Future<void> resendVerification() =>
      _run(() => ref.read(authRepositoryProvider).sendVerificationEmail());

  /// Returns whether the email is now verified.
  Future<bool> checkVerified() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).reloadVerified(),
    );
    state = result.whenData((_) {});
    return result.value ?? false;
  }

  Future<void> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
