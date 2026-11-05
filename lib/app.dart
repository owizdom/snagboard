import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/auth_gate.dart';

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
