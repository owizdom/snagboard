import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Full-width flat button: ink by default, flare when [accent] is true.
/// While [loading] it shows a spinner and cannot be pressed.
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final style = accent
        ? FilledButton.styleFrom(
            backgroundColor: Snag.flare,
            foregroundColor: Snag.ink,
            side: Snag.border,
          )
        : null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: style,
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(label),
      ),
    );
  }
}
