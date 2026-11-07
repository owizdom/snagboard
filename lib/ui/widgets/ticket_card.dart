import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../keys.dart';
import 'category_box.dart';
import 'status_stamp.dart';
import 'ticket_shape.dart';

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
