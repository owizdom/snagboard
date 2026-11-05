import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// An outlined, tappable option that turns ink when chosen. Used for
/// locations and urgency.
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        excludeSemantics: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? Snag.ink : null,
              border: Border.all(color: Snag.ink, width: Snag.outline),
              borderRadius: BorderRadius.circular(Snag.radius),
            ),
            child: Text(label, style: Snag.label(size: 13, color: selected ? Snag.paper : Snag.ink)),
          ),
        ),
      );
}
