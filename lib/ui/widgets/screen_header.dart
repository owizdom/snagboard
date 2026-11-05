import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Typographic page header: big mono caps title and a small line under it.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.child});
  final String title;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.05)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Snag.label(size: 12, color: Snag.inkSoft)),
            ],
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      );
}
