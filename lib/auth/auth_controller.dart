import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs auth actions and exposes their progress as AsyncValue: loading
/// while a call runs, error with the message to show, data when done.
/// Every method delegates to `authRepositoryProvider`.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) =>
      throw UnimplementedError();

  Future<void> signUp(String name, String email, String password) =>
      throw UnimplementedError();

  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  Future<void> resendVerification() => throw UnimplementedError();

  /// Returns whether the email is now verified.
  Future<bool> checkVerified() => throw UnimplementedError();

  Future<void> signOut() => throw UnimplementedError();
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
