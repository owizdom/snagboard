import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../keys.dart';
import '../widgets/ink_button.dart';
import '../widgets/ink_field.dart';
import '../widgets/messages.dart';
import 'sign_up_screen.dart';

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
    ref.read(authControllerProvider.notifier).signIn(_email.text.trim(), _password.text);
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
      ..showSnackBar(SnackBar(
        content: Text(state.hasError
            ? errorMessage(state.error!)
            : 'If $email has an account, a reset link is on its way.'),
      ));
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
                Text('snag (n.): something on campus that needs fixing',
                    style: Snag.label(size: 12, color: Snag.inkSoft).copyWith(letterSpacing: 0.2)),
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password.' : null,
                ),
                if (auth.hasError && !auth.isLoading) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage(auth.error!), style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                InkButton(key: K.signInSubmit, label: 'SIGN IN', loading: auth.isLoading, onPressed: _signIn),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(key: K.signInForgot, onPressed: auth.isLoading ? null : _forgot, child: const Text('FORGOT PASSWORD')),
                ),
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: K.signInToSignUp,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
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
    const style = TextStyle(fontSize: 72, fontWeight: FontWeight.w700, height: 0.95, letterSpacing: -2);
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
            Text.rich(const TextSpan(children: [
              TextSpan(text: '/', style: TextStyle(color: Snag.flare)),
              TextSpan(text: 'BOARD'),
            ]), style: style),
          ],
        ),
      ),
    );
  }
}
