import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/firebase_options.dart';
import 'package:snagboard/ui/auth_screens.dart';
import 'package:snagboard/ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // No automatic retries: a failed load shows its error panel (with Retry
  // and Sign out) straight away instead of an endless spinner.
  runApp(ProviderScope(retry: (_, _) => null, child: const SnagboardApp()));
}

class SnagboardApp extends StatelessWidget {
  const SnagboardApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Snagboard',
    debugShowCheckedModeBanner: false,
    theme: buildSnagTheme(),
    home: const AuthGate(),
  );
}
