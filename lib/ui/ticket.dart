import 'package:flutter/material.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/ui/theme.dart';

/// A ticket outline: ink border, 4 px corners, a half-circle notch at the top
/// and bottom of the perforation line, and a dashed line between them.
/// [stubWidth] is how far from the left edge the perforation sits.
class TicketShape extends StatelessWidget {
  const TicketShape({super.key, required this.child, this.stubWidth = 76});
  final Widget child;
  final double stubWidth;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TicketPainter(stubWidth), child: child);
}

class _TicketPainter extends CustomPainter {
  _TicketPainter(this.stubWidth);
  final double stubWidth;

  static const _notch = 8.0;
  static const _fill = Color(0xFFFBF9F3);

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Snag.radius),
        ),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(stubWidth, 0), radius: _notch))
      ..addOval(
        Rect.fromCircle(center: Offset(stubWidth, size.height), radius: _notch),
      );
    final shape = Path.combine(PathOperation.difference, body, notches);
    canvas.drawPath(shape, Paint()..color = _fill);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Snag.outline
        ..color = Snag.ink,
    );
    final dash = Paint()
      ..strokeWidth = 1.5
      ..color = Snag.ink;
    for (var y = _notch + 6; y < size.height - _notch - 6; y += 9) {
      canvas.drawLine(Offset(stubWidth, y), Offset(stubWidth, y + 5), dash);
    }
  }

  @override
  bool shouldRepaint(_TicketPainter old) => old.stubWidth != stubWidth;
}

/// One snag on the board, drawn as a ticket stub.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.incident, required this.onTap});
  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i = incident;
    final place = (i.spot == null || i.spot!.isEmpty)
        ? i.location
        : '${i.location}, ${i.spot}';
    final small = Snag.label(
      size: 11,
      color: Snag.inkSoft,
    ).copyWith(letterSpacing: 0.4);
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: TicketShape(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryBox(i.category),
                    const SizedBox(height: 8),
                    Text(timeAgo(i.createdAt, DateTime.now()), style: small),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              i.ticketCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Snag.label(size: 12, color: Snag.inkSoft),
                            ),
                          ),
                          if (i.urgency == Urgency.urgent) ...[
                            const SizedBox(width: 8),
                            Text(
                              'URGENT',
                              style: Snag.label(size: 11, color: Snag.danger),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Snag.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // The stamp sits on the bottom line so a photo, URGENT and a long
                      // status never crowd one row.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'AFFECTS ${i.affectedBy.length}',
                              style: small,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusStamp(
                            key: K.ticketStamp(i.id),
                            status: i.status,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // The snag's photo, when it has one.
              if (i.photoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: Snag.ink, width: Snag.outline),
                      borderRadius: BorderRadius.circular(Snag.radius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      i.photoUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: 'Photo of the snag',
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        Text(
          category.code,
          style: Snag.label(size: 15, color: inverted ? Snag.paper : Snag.ink),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            category.label.toUpperCase(),
            style: Snag.label(
              size: 8,
              color: inverted ? Snag.paper : Snag.inkSoft,
            ).copyWith(letterSpacing: 0.3),
          ),
        ),
      ],
    ),
  );
}

/// A rubber-stamp label: caps, outlined, tilted a little.
class Stamp extends StatelessWidget {
  const Stamp({
    super.key,
    required this.label,
    required this.color,
    this.size = 11,
  });
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
      child: Text(
        label,
        style: Snag.label(size: size, color: color),
      ),
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
  const _Stop({
    required this.entry,
    required this.isLatest,
    required this.hasLineBelow,
  });
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
                if (hasLineBelow)
                  Expanded(
                    child: Container(width: Snag.outline, color: Snag.ink),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: hasLineBelow ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.status.label.toUpperCase(),
                    style: Snag.label(size: 13, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.byName}  ${formatDateTime(entry.at)}',
                    style: Snag.label(
                      size: 11,
                      color: Snag.inkSoft,
                    ).copyWith(letterSpacing: 0.3),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.note,
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),
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

  static const _groups = [
    StatusGroup.open,
    StatusGroup.active,
    StatusGroup.closed,
  ];

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
            flex:
                100 +
                (total == 0 ? 100 : (300 * (counts[g] ?? 0) / total).round()),
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
