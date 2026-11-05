import 'package:flutter/material.dart';

/// Signed out -> SignInScreen; signed in but unverified -> VerifyEmailScreen;
/// verified -> HomeShell. Loading shows K.gateLoading; errors show K.gateError
/// with a K.gateRetry button.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
