import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/state/auth_state.dart';
import 'package:snagboard/state/incident_state.dart';
import 'package:snagboard/state/report_form.dart';
import 'package:snagboard/ui/theme.dart';
import 'package:snagboard/ui/ticket.dart';
import 'package:snagboard/ui/widgets.dart';

/// Four steps: 1 WHAT, 2 WHERE, 3 DETAILS, 4 REVIEW. Pass [editing] to
/// change the details of a snag that is still submitted.
class FileSnagScreen extends ConsumerStatefulWidget {
  const FileSnagScreen({super.key, this.editing});
  final Incident? editing;

  @override
  ConsumerState<FileSnagScreen> createState() => _FileSnagScreenState();
}

class _FileSnagScreenState extends ConsumerState<FileSnagScreen> {
  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      Future.microtask(() {
        if (mounted) ref.read(reportFormProvider.notifier).startEdit(editing);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the profile and the board loaded: submitting and the duplicate
    // check both need them.
    ref.watch(currentUserProvider);
    final form = ref.watch(reportFormProvider);
    final ctrl = ref.read(reportFormProvider.notifier);
    final editing = widget.editing != null;

    ref.listen(reportFormProvider, (prev, next) {
      if (next.done && !(prev?.done ?? false)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(editing ? 'Changes saved.' : 'Snag filed.')),
          );
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    });

    final body = switch (form.step) {
      0 => const WhatStep(),
      1 => WhereStep(editingId: widget.editing?.id),
      2 => const DetailsStep(),
      _ => const ReviewStep(),
    };
    final last = form.step == reportStepCount - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'EDIT SNAG' : 'FILE A SNAG',
          style: Snag.label(size: 14),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StepRail(step: form.step),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: body,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: Snag.border)),
              child: Row(
                children: [
                  if (form.step > 0) ...[
                    SizedBox(
                      width: 110,
                      child: OutlinedButton(
                        key: K.back,
                        onPressed: form.submitting ? null : ctrl.back,
                        child: const Text('BACK'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: _primary(last, form, ctrl, editing)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primary(
    bool last,
    ReportFormState form,
    ReportFormController ctrl,
    bool editing,
  ) {
    if (!last) {
      return InkButton(key: K.next, label: 'NEXT', onPressed: ctrl.next);
    }
    if (form.error != null) {
      return InkButton(
        key: K.submitRetry,
        label: 'RETRY',
        accent: true,
        loading: form.submitting,
        onPressed: ctrl.submit,
      );
    }
    return InkButton(
      key: K.submit,
      label: editing ? 'SAVE CHANGES' : 'SUBMIT SNAG',
      accent: true,
      loading: form.submitting,
      onPressed: ctrl.submit,
    );
  }
}

/// The 1 WHAT / 2 WHERE / 3 DETAILS / 4 REVIEW rail at the top of filing.
class StepRail extends StatelessWidget {
  const StepRail({super.key, required this.step});
  final int step;

  static const _names = ['WHAT', 'WHERE', 'DETAILS', 'REVIEW'];

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${step + 1} of ${_names.length}: ${_names[step]}',
    excludeSemantics: true,
    child: Row(
      children: [
        for (var n = 0; n < _names.length; n++)
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: n == step
                    ? Snag.ink
                    : (n < step ? Snag.paperDeep : null),
                border: Border(
                  top: Snag.border,
                  bottom: Snag.border,
                  left: Snag.border,
                  right: n == _names.length - 1 ? Snag.border : BorderSide.none,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${n + 1} ${_names[n]}',
                  style: Snag.label(
                    size: 11,
                    color: n == step ? Snag.paper : Snag.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

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
            child: Text(
              error,
              key: K.fieldError,
              style: const TextStyle(
                color: Snag.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              style: TextStyle(
                color: Snag.danger,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
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
  const _CategoryRow({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });
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
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  Text(
                    category.hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Snag.paperDeep : Snag.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2: pick a place, add a spot, and see open snags already filed there.
class WhereStep extends ConsumerStatefulWidget {
  const WhereStep({super.key, this.editingId});
  final String? editingId;

  @override
  ConsumerState<WhereStep> createState() => _WhereStepState();
}

class _WhereStepState extends ConsumerState<WhereStep> {
  late final TextEditingController _spot = TextEditingController(
    text: ref.read(reportFormProvider).draft.spot ?? '',
  );

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
        : findSimilar(
            all,
            category,
            location,
          ).where((i) => i.id != widget.editingId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('WHERE IS IT?'),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              error,
              key: K.fieldError,
              style: const TextStyle(
                color: Snag.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      ..showSnackBar(
        SnackBar(
          content: Text(err ?? 'Added. You are counted on ${i.ticketCode}.'),
        ),
      );
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
        const Text(
          'Open snags with the same category and place. Add yourself instead of filing a duplicate.',
          style: TextStyle(height: 1.35),
        ),
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
                Row(
                  children: [
                    Text(
                      i.ticketCode,
                      style: Snag.label(size: 12, color: Snag.inkSoft),
                    ),
                    const Spacer(),
                    StatusStamp(status: i.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  i.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AFFECTS ${i.affectedBy.length}',
                  style: Snag.label(size: 11, color: Snag.inkSoft),
                ),
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

/// Step 3: title, description, optional photo, and the anonymous switch.
class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({super.key});

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final _title = TextEditingController(
    text: ref.read(reportFormProvider).draft.title,
  );
  late final _description = TextEditingController(
    text: ref.read(reportFormProvider).draft.description,
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await ref.read(photoPickerProvider).pick(fromCamera: false);
    if (path != null) ref.read(reportFormProvider.notifier).setPhoto(path);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(reportFormProvider);
    final ctrl = ref.read(reportFormProvider.notifier);
    final photo = form.draft.photoPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('TELL US MORE'),
        InkField(
          key: K.title,
          label: 'TITLE',
          controller: _title,
          onChanged: ctrl.setTitle,
          errorText: form.errors['title'],
          maxLength: 80,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        InkField(
          key: K.description,
          label: 'WHAT IS WRONG?',
          controller: _description,
          onChanged: ctrl.setDescription,
          errorText: form.errors['description'],
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
        ),
        const SectionLabel('PHOTO'),
        if (form.isEditing)
          const Text('The photo cannot be changed after filing.')
        else if (photo == null)
          OutlinedButton.icon(
            key: K.addPhoto,
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('ADD A PHOTO (OPTIONAL)'),
          )
        else
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  border: Border.all(color: Snag.ink, width: Snag.outline),
                ),
                child: Image.file(
                  File(photo),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.image_outlined)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                key: K.removePhoto,
                onPressed: () => ctrl.setPhoto(null),
                child: const Text('REMOVE PHOTO'),
              ),
            ],
          ),
        const SizedBox(height: 16),
        SwitchListTile(
          key: K.anonymous,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Snag.ink,
          title: const Text(
            'Hide my name from other students; staff still see it',
          ),
          value: form.draft.anonymous,
          onChanged: ctrl.setAnonymous,
        ),
      ],
    );
  }
}

/// Step 4: the draft as a ticket preview, plus submit progress and errors.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reportFormProvider);
    final d = form.draft;
    final place = (d.spot == null || d.spot!.trim().isEmpty)
        ? d.location ?? ''
        : '${d.location}, ${d.spot}';
    final small = Snag.label(
      size: 11,
      color: Snag.inkSoft,
    ).copyWith(letterSpacing: 0.4);
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
                  child: Column(
                    children: [
                      if (d.category != null) CategoryBox(d.category!),
                      const SizedBox(height: 8),
                      Text('NEW', style: small),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(place, style: const TextStyle(color: Snag.inkSoft)),
                      const SizedBox(height: 8),
                      Text(d.description, style: const TextStyle(height: 1.35)),
                      const SizedBox(height: 10),
                      Text(
                        '${d.urgency.label.toUpperCase()}'
                        '${d.anonymous ? '  ·  NAME HIDDEN' : ''}',
                        style: small,
                      ),
                      // The picked photo, so the student sees what will be sent.
                      if (d.photoPath != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Snag.radius),
                          child: Image.file(
                            File(d.photoPath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Text('PHOTO ATTACHED', style: small),
                          ),
                        ),
                      ],
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
          Text(
            form.error!,
            style: const TextStyle(
              color: Snag.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
