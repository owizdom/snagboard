import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../keys.dart';

/// One bar split into OPEN / ACTIVE / CLOSED, wider where there are more
/// snags. Tapping a segment filters by it; tapping the chosen one clears it.
class StatusRibbon extends StatelessWidget {
  const StatusRibbon({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<StatusGroup, int> counts;
  final StatusGroup selected;
  final ValueChanged<StatusGroup> onSelect;

  static const _groups = [StatusGroup.open, StatusGroup.active, StatusGroup.closed];

  static Color _color(StatusGroup g) => switch (g) {
        StatusGroup.open => Snag.statusColor(IncidentStatus.submitted),
        StatusGroup.active => Snag.statusColor(IncidentStatus.inProgress),
        _ => Snag.statusColor(IncidentStatus.resolved),
      };

  @override
  Widget build(BuildContext context) {
    final total = _groups.fold<int>(0, (sum, g) => sum + (counts[g] ?? 0));
    return Row(
      children: [
        for (final g in _groups)
          Expanded(
            // Every segment keeps a minimum width so its label always fits.
            flex: 100 + (total == 0 ? 100 : (300 * (counts[g] ?? 0) / total).round()),
            child: _Segment(
              key: K.ribbonSegment(g),
              group: g,
              count: counts[g] ?? 0,
              chosen: selected == g,
              isLast: g == _groups.last,
              onTap: () => onSelect(selected == g ? StatusGroup.all : g),
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.group,
    required this.count,
    required this.chosen,
    required this.isLast,
    required this.onTap,
  });

  final StatusGroup group;
  final int count;
  final bool chosen;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = group.name.toUpperCase();
    final fg = chosen ? Snag.paper : Snag.ink;
    return Semantics(
      button: true,
      selected: chosen,
      label: '$name, $count snags. Tap to filter.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            color: chosen ? Snag.ink : Snag.paperDeep,
            border: Border(
              top: Snag.border,
              bottom: Snag.border,
              left: Snag.border,
              right: isLast ? Snag.border : BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text('$count', style: Snag.label(size: 22, color: fg)),
              Text(name, style: Snag.label(size: 11, color: fg)),
              const SizedBox(height: 6),
              Container(height: 6, color: StatusRibbon._color(group)),
            ],
          ),
        ),
      ),
    );
  }
}
