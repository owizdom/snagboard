import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../incidents/report_form_controller.dart';
import '../keys.dart';
import 'category_box.dart';
import 'ink_field.dart';
import 'ticket_shape.dart';

/// Step 4: the draft as a ticket preview, plus submit progress and errors.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final d = form.draft;
    final place = (d.spot == null || d.spot!.trim().isEmpty) ? d.location ?? '' : '${d.location}, ${d.spot}';
    final small = Snag.label(size: 11, color: Snag.inkSoft).copyWith(letterSpacing: 0.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('REVIEW YOUR TICKET'),
        TicketShape(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(children: [
                    if (d.category != null) CategoryBox(d.category!),
                    const SizedBox(height: 8),
                    Text('NEW', style: small),
                  ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(place, style: const TextStyle(color: Snag.inkSoft)),
                      const SizedBox(height: 8),
                      Text(d.description, style: const TextStyle(height: 1.35)),
                      const SizedBox(height: 10),
                      Text(
                        '${d.urgency.label.toUpperCase()} URGENCY'
                        '${d.photoPath != null ? '  PHOTO ATTACHED' : ''}'
                        '${d.anonymous ? '  NAME HIDDEN' : ''}',
                        style: small,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (form.submitting) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            key: K.submitProgress,
            value: form.progress > 0 ? form.progress : null,
            color: Snag.ink,
            backgroundColor: Snag.paperDeep,
            minHeight: 8,
          ),
        ],
        if (form.error != null) ...[
          const SizedBox(height: 16),
          Text(form.error!, style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}
