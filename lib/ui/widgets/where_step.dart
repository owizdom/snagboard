import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../core/campus.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_actions.dart';
import '../../incidents/incident_providers.dart';
import '../../incidents/report_form_controller.dart';
import '../../incidents/similar.dart';
import '../keys.dart';
import 'choice_box.dart';
import 'ink_field.dart';
import 'messages.dart';
import 'status_stamp.dart';

/// Step 2: pick a place, add a spot, and see open snags already filed there.
class WhereStep extends ConsumerStatefulWidget {
  const WhereStep({super.key, this.editingId});
  final String? editingId;

  @override
  ConsumerState<WhereStep> createState() => _WhereStepState();
}

class _WhereStepState extends ConsumerState<WhereStep> {
  late final TextEditingController _spot =
      TextEditingController(text: ref.read(reportFormProvider).draft.spot ?? '');

  @override
  void dispose() {
    _spot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(reportFormProvider);
    final ctrl = ref.read(reportFormProvider.notifier);
    final error = form.errors['location'];
    final category = form.draft.category;
    final location = form.draft.location;
    final all = ref.watch(incidentsProvider).value ?? const <Incident>[];
    final similar = (category == null || location == null)
        ? const <Incident>[]
        : findSimilar(all, category, location).where((i) => i.id != widget.editingId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('WHERE IS IT?'),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, key: K.fieldError, style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in campusLocations)
              ChoiceBox(
                key: K.locationOption(name),
                label: name.toUpperCase(),
                selected: location == name,
                onTap: () => ctrl.setLocation(name),
              ),
          ],
        ),
        const SizedBox(height: 16),
        InkField(
          key: K.spot,
          label: 'ROOM OR EXACT SPOT (OPTIONAL)',
          controller: _spot,
          onChanged: ctrl.setSpot,
          maxLength: 60,
        ),
        if (similar.isNotEmpty) _SimilarBlock(similar: similar),
      ],
    );
  }
}

class _SimilarBlock extends ConsumerWidget {
  const _SimilarBlock({required this.similar});
  final List<Incident> similar;

  Future<void> _affects(BuildContext context, WidgetRef ref, Incident i) async {
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final err = await runAction(
      container,
      () => ref.read(incidentActionsProvider.notifier).toggleAffected(i),
      (c) => c.read(incidentActionsProvider),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(err ?? 'Added. You are counted on ${i.ticketCode}.')));
    if (err == null && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).value?.uid;
    return Column(
      key: K.similarList,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('ALREADY REPORTED?'),
        const Text('Open snags with the same category and place. Add yourself instead of filing a duplicate.',
            style: TextStyle(height: 1.35)),
        const SizedBox(height: 12),
        for (final i in similar)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Snag.ink, width: Snag.outline),
              borderRadius: BorderRadius.circular(Snag.radius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(i.ticketCode, style: Snag.label(size: 12, color: Snag.inkSoft)),
                  const Spacer(),
                  StatusStamp(status: i.status),
                ]),
                const SizedBox(height: 6),
                Text(i.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('AFFECTS ${i.affectedBy.length}', style: Snag.label(size: 11, color: Snag.inkSoft)),
                const SizedBox(height: 8),
                if (i.reporterId == uid)
                  Text('YOU FILED THIS ONE', style: Snag.label(size: 12))
                else if (i.affectedBy.contains(uid))
                  Text('YOU ARE ALREADY COUNTED', style: Snag.label(size: 12))
                else
                  OutlinedButton(
                    key: K.similarAffects(i.id),
                    onPressed: () => _affects(context, ref, i),
                    child: const Text('AFFECTS ME TOO'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
