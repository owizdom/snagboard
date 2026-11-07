import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/auth_repository.dart';
import 'package:snagboard/data/models.dart';

/// Overridden with fakes in tests.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(),
);

final sessionProvider = StreamProvider<AuthSession?>(
  (ref) => ref.watch(authRepositoryProvider).sessionChanges(),
);

/// The profile of a signed-in, verified user; null otherwise.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final session = ref.watch(sessionProvider).value;
  if (session == null || !session.emailVerified) {
    return Stream.value(null);
  }
  return ref.watch(profileRepositoryProvider).watch(session.uid);
});

/// The display name on any user's profile. Only staff may read other
/// profiles, so only staff screens use this.
final displayNameProvider = StreamProvider.family<String?, String>(
  (ref, uid) => ref
      .watch(profileRepositoryProvider)
      .watch(uid)
      .map((u) => u?.displayName),
);

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
