import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../keys.dart';
import '../widgets/ink_button.dart';
import '../widgets/ink_field.dart';
import '../widgets/messages.dart';

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
    if (!container.read(authControllerProvider).hasError && navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text('CREATE ACCOUNT', style: Snag.label(size: 14))),
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
                InkField(key: K.signUpName, label: 'FULL NAME', controller: _name, validator: validateName,
                    textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
                InkField(key: K.signUpEmail, label: 'ALU EMAIL', controller: _email, validator: validateAluEmail,
                    keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
                InkField(key: K.signUpPassword, label: 'PASSWORD', controller: _password, obscure: true,
                    validator: validatePassword),
                const SizedBox(height: 16),
                InkField(key: K.signUpConfirm, label: 'CONFIRM PASSWORD', controller: _confirm, obscure: true,
                    validator: (v) => validateConfirm(v, _password.text)),
                if (auth.hasError && !auth.isLoading) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage(auth.error!), style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                InkButton(key: K.signUpSubmit, label: 'CREATE ACCOUNT', loading: auth.isLoading, onPressed: _submit),
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
