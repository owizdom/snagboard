import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../incidents/incident.dart';

/// The three-letter category code in an outlined box, e.g. WTR.
class CategoryBox extends StatelessWidget {
  const CategoryBox(this.category, {super.key, this.inverted = false});
  final IncidentCategory category;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Container(
        width: 54,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inverted ? Snag.ink : null,
          border: Border.all(color: Snag.ink, width: Snag.outline),
          borderRadius: BorderRadius.circular(Snag.radius),
        ),
        child: Text(
          category.code,
          style: Snag.label(size: 15, color: inverted ? Snag.paper : Snag.ink),
        ),
      );
}
