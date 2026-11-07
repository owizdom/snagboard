import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/state/auth_state.dart';
import 'package:snagboard/state/report_form.dart';
import 'package:snagboard/ui/home_screens.dart';
import 'package:snagboard/ui/theme.dart';
import 'package:snagboard/ui/widgets.dart';

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

    return ref
        .watch(sessionProvider)
        .when(
          loading: () => loading,
          error: (_, _) => error('Could not check your sign-in.'),
          data: (session) {
            if (session == null) return const SignInScreen();
            if (!session.emailVerified) return const VerifyEmailScreen();
            return ref
                .watch(currentUserProvider)
                .when(
                  loading: () => loading,
                  error: (_, _) => error('Could not load your profile.'),
                  data: (user) => user == null
                      ? error('No profile found for this account.')
                      : const HomeShell(),
                );
          },
        );
  }
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Forget an error left over from another auth screen.
    Future.microtask(() {
      if (mounted) ref.invalidate(authControllerProvider);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_form.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
  }

  Future<void> _forgot() async {
    final problem = validateAluEmail(_email.text.trim());
    if (problem != null) {
      showSnack(context, 'Enter your ALU email first. $problem');
      return;
    }
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = _email.text.trim();
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    final state = container.read(authControllerProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            state.hasError
                ? errorMessage(state.error!)
                : 'If $email has an account, a reset link is on its way.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const _Wordmark(),
                const SizedBox(height: 12),
                Text(
                  'snag (n.): something on campus that needs fixing',
                  style: Snag.label(
                    size: 12,
                    color: Snag.inkSoft,
                  ).copyWith(letterSpacing: 0.2),
                ),
                const SizedBox(height: 32),
                InkField(
                  key: K.signInEmail,
                  label: 'ALU EMAIL',
                  controller: _email,
                  validator: validateAluEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                InkField(
                  key: K.signInPassword,
                  label: 'PASSWORD',
                  controller: _password,
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password.' : null,
                ),
                if (auth.hasError && !auth.isLoading) ...[
                  const SizedBox(height: 12),
                  ErrorText(errorMessage(auth.error!)),
                ],
                const SizedBox(height: 20),
                InkButton(
                  key: K.signInSubmit,
                  label: 'SIGN IN',
                  loading: auth.isLoading,
                  onPressed: _signIn,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: K.signInForgot,
                    onPressed: auth.isLoading ? null : _forgot,
                    child: const Text('FORGOT PASSWORD'),
                  ),
                ),
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: K.signInToSignUp,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignUpScreen(),
                      ),
                    ),
                    child: const Text('NEW HERE? CREATE AN ACCOUNT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SNAG on one line, /BOARD on the next, in heavy type.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 72,
      fontWeight: FontWeight.w700,
      height: 0.95,
      letterSpacing: -2,
    );
    return Semantics(
      label: 'Snagboard',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SNAG', style: style),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: '/',
                    style: TextStyle(color: Snag.flare),
                  ),
                  TextSpan(text: 'BOARD'),
                ],
              ),
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(authControllerProvider);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    await ref
        .read(authControllerProvider.notifier)
        .signUp(_name.text.trim(), _email.text.trim(), _password.text);
    // On success leave this screen; AuthGate then shows the verify screen.
    if (!container.read(authControllerProvider).hasError &&
        navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('CREATE ACCOUNT', style: Snag.label(size: 14)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Only @alustudent.com and @alueducation.com addresses can join.',
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 20),
                InkField(
                  key: K.signUpName,
                  label: 'FULL NAME',
                  controller: _name,
                  validator: validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                InkField(
                  key: K.signUpEmail,
                  label: 'ALU EMAIL',
                  controller: _email,
                  validator: validateAluEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                InkField(
                  key: K.signUpPassword,
                  label: 'PASSWORD',
                  controller: _password,
                  obscure: true,
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),
                InkField(
                  key: K.signUpConfirm,
                  label: 'CONFIRM PASSWORD',
                  controller: _confirm,
                  obscure: true,
                  validator: (v) => validateConfirm(v, _password.text),
                ),
                if (auth.hasError && !auth.isLoading) ...[
                  const SizedBox(height: 12),
                  ErrorText(errorMessage(auth.error!)),
                ],
                const SizedBox(height: 20),
                InkButton(
                  key: K.signUpSubmit,
                  label: 'CREATE ACCOUNT',
                  loading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: K.signUpToSignIn,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('HAVE AN ACCOUNT? SIGN IN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      verified = await ref
          .read(authControllerProvider.notifier)
          .checkVerified();
    } catch (_) {}
    if (verified) return; // the session changes and AuthGate moves on
    final state = container.read(authControllerProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            state.hasError ? errorMessage(state.error!) : 'Not verified yet. Open the link in your email, then try again.',
          ),
        ),
      );
  }

  Future<void> _resend() async {
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
    } catch (_) {}
    final state = container.read(authControllerProvider);
    if (state.hasError) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorMessage(state.error!))),
      );
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
              const Text(
                'CHECK YOUR INBOX',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We sent a verification link to',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(email, style: Snag.label(size: 15)),
              const SizedBox(height: 12),
              const Text(
                'Open it, then come back and tap the button below.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 28),
              InkButton(
                key: K.verifyCheck,
                label: "I'VE VERIFIED",
                accent: true,
                onPressed: _check,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: K.verifyResend,
                  onPressed: _left > 0 ? null : _resend,
                  child: Text(
                    _left > 0 ? 'RESEND IN ${_left}S' : 'RESEND EMAIL',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: K.verifyUseAnother,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('USE ANOTHER ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
