import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// An error message with a retry button. [retryKey] goes on the button.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry, this.retryKey});
  final String message;
  final VoidCallback onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SOMETHING WENT WRONG', style: Snag.label(size: 14, color: Snag.danger)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Snag.inkSoft)),
              const SizedBox(height: 16),
              OutlinedButton(key: retryKey, onPressed: onRetry, child: const Text('RETRY')),
            ],
          ),
        ),
      );
}
