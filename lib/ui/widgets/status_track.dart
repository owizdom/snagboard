import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';

/// The ticket log: one stop per history entry, oldest first, each with the
/// status, who changed it, when, and the note they left.
class StatusTrack extends StatelessWidget {
  const StatusTrack({super.key, required this.history});
  final List<StatusChange> history;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var n = 0; n < history.length; n++)
            _Stop(
              entry: history[n],
              isLatest: n == history.length - 1,
              hasLineBelow: n < history.length - 1,
            ),
        ],
      );
}

class _Stop extends StatelessWidget {
  const _Stop({required this.entry, required this.isLatest, required this.hasLineBelow});
  final StatusChange entry;
  final bool isLatest;
  final bool hasLineBelow;

  @override
  Widget build(BuildContext context) {
    final color = Snag.statusColor(entry.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isLatest ? color : Snag.paper,
                    border: Border.all(color: Snag.ink, width: Snag.outline),
                  ),
                ),
                if (hasLineBelow) Expanded(child: Container(width: Snag.outline, color: Snag.ink)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: hasLineBelow ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.status.label.toUpperCase(), style: Snag.label(size: 13, color: color)),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.byName}  ${formatDateTime(entry.at)}',
                    style: Snag.label(size: 11, color: Snag.inkSoft).copyWith(letterSpacing: 0.3),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entry.note, style: const TextStyle(fontSize: 15, height: 1.3)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
