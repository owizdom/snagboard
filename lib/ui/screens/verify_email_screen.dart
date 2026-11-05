import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_providers.dart';
import '../../core/theme.dart';
import '../keys.dart';
import '../widgets/ink_button.dart';
import '../widgets/messages.dart';

/// Resend is disabled for 60 seconds after each send.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldown = 60;
  int _left = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _left = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _check() async {
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    var verified = false;
    try {
      verified = await ref.read(authControllerProvider.notifier).checkVerified();
    } catch (_) {}
    if (verified) return; // the session changes and AuthGate moves on
    final state = container.read(authControllerProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(state.hasError
            ? errorMessage(state.error!)
            : 'Not verified yet. Open the link in your email, then try again.'),
      ));
  }

  Future<void> _resend() async {
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
    } catch (_) {}
    final state = container.read(authControllerProvider);
    if (state.hasError) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(state.error!))));
      return;
    }
    if (mounted) _startCooldown();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Verification email sent.')));
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionProvider).value?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('CHECK YOUR INBOX',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.05)),
              const SizedBox(height: 16),
              const Text('We sent a verification link to', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(email, style: Snag.label(size: 15)),
              const SizedBox(height: 12),
              const Text('Open it, then come back and tap the button below.',
                  style: TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 28),
              InkButton(key: K.verifyCheck, label: "I'VE VERIFIED", accent: true, onPressed: _check),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: K.verifyResend,
                  onPressed: _left > 0 ? null : _resend,
                  child: Text(_left > 0 ? 'RESEND IN ${_left}S' : 'RESEND EMAIL'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: K.verifyUseAnother,
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('USE ANOTHER ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
