import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../incidents/incident.dart';

/// A rubber-stamp label: caps, outlined, tilted a little.
class Stamp extends StatelessWidget {
  const Stamp({super.key, required this.label, required this.color, this.size = 11});
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -0.05,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: Snag.outline),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label, style: Snag.label(size: size, color: color)),
        ),
      );
}

/// The stamp for a snag's status, in that status's colour.
class StatusStamp extends StatelessWidget {
  const StatusStamp({super.key, required this.status, this.size = 11});
  final IncidentStatus status;
  final double size;

  @override
  Widget build(BuildContext context) => Stamp(
        label: status.label.toUpperCase(),
        color: Snag.statusColor(status),
        size: size,
      );
}
