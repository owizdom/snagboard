import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../incidents/incident.dart';

/// The category in an outlined box: code (WTR) with the full name under it.
class CategoryBox extends StatelessWidget {
  const CategoryBox(this.category, {super.key, this.inverted = false});
  final IncidentCategory category;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inverted ? Snag.ink : null,
          border: Border.all(color: Snag.ink, width: Snag.outline),
          borderRadius: BorderRadius.circular(Snag.radius),
        ),
        // Code on top, full name under it, so nobody has to guess "SAN".
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.code, style: Snag.label(size: 15, color: inverted ? Snag.paper : Snag.ink)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                category.label.toUpperCase(),
                style: Snag.label(size: 8, color: inverted ? Snag.paper : Snag.inkSoft).copyWith(letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      );
}
