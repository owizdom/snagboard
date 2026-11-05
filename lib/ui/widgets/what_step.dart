import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/report_form_controller.dart';
import '../keys.dart';
import 'category_box.dart';
import 'choice_box.dart';
import 'ink_field.dart';

/// Step 1: pick a category and how urgent it is.
class WhatStep extends ConsumerWidget {
  const WhatStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final ctrl = ref.read(reportFormProvider.notifier);
    final error = form.errors['category'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('WHAT KIND OF SNAG?'),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, key: K.fieldError, style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700)),
          ),
        for (final c in IncidentCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryRow(
              key: K.categoryRow(c),
              category: c,
              selected: form.draft.category == c,
              onTap: () => ctrl.setCategory(c),
            ),
          ),
        if (form.draft.category == IncidentCategory.safety)
          Container(
            key: K.safetyNotice,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Snag.danger, width: Snag.outline),
              borderRadius: BorderRadius.circular(Snag.radius),
            ),
            child: const Text(
              'This app is not monitored around the clock. If anyone is in immediate danger, contact campus security first.',
              style: TextStyle(color: Snag.danger, fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        const SectionLabel('HOW URGENT?'),
        Row(
          children: [
            for (final u in Urgency.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceBox(
                    key: K.urgencyOption(u),
                    label: u.label.toUpperCase(),
                    selected: form.draft.urgency == u,
                    onTap: () => ctrl.setUrgency(u),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({super.key, required this.category, required this.selected, required this.onTap});
  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Snag.paper : Snag.ink;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Snag.ink : null,
          border: Border.all(color: Snag.ink, width: Snag.outline),
          borderRadius: BorderRadius.circular(Snag.radius),
        ),
        child: Row(
          children: [
            CategoryBox(category, inverted: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
                  Text(category.hint, style: TextStyle(fontSize: 13, color: selected ? Snag.paperDeep : Snag.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
