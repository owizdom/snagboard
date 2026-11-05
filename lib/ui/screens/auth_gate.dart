import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_providers.dart';
import '../keys.dart';
import '../widgets/error_panel.dart';
import 'home_shell.dart';
import 'sign_in_screen.dart';
import 'verify_email_screen.dart';

/// Signed out -> SignInScreen; signed in but unverified -> VerifyEmailScreen;
/// verified -> HomeShell. Loading shows K.gateLoading; errors show K.gateError
/// with a K.gateRetry button.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() {
      ref.invalidate(sessionProvider);
      ref.invalidate(currentUserProvider);
    }

    // Errors offer sign out too, so a broken account is never a dead end.
    Widget error(String message) => Scaffold(
          body: ErrorPanel(
            key: K.gateError,
            retryKey: K.gateRetry,
            message: message,
            onRetry: retry,
            extra: TextButton(
              key: K.gateSignOut,
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('SIGN OUT'),
            ),
          ),
        );
    const loading = Scaffold(
      body: Center(key: K.gateLoading, child: CircularProgressIndicator()),
    );

    return ref.watch(sessionProvider).when(
          loading: () => loading,
          error: (_, _) => error('Could not check your sign-in.'),
          data: (session) {
            if (session == null) return const SignInScreen();
            if (!session.emailVerified) return const VerifyEmailScreen();
            return ref.watch(currentUserProvider).when(
                  loading: () => loading,
                  error: (_, _) => error('Could not load your profile.'),
                  data: (user) =>
                      user == null ? error('No profile found for this account.') : const HomeShell(),
                );
          },
        );
  }
}
