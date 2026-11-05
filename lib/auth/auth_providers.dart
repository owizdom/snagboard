import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/firestore_profile_repository.dart';
import '../profile/profile_repository.dart';
import 'app_user.dart';
import 'auth_repository.dart';
import 'firebase_auth_repository.dart';

/// Overridden with fakes in tests.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => FirebaseAuthRepository());

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => FirestoreProfileRepository());

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
