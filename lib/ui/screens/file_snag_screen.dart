import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/report_form_controller.dart';
import '../keys.dart';
import '../widgets/details_step.dart';
import '../widgets/ink_button.dart';
import '../widgets/review_step.dart';
import '../widgets/step_rail.dart';
import '../widgets/what_step.dart';
import '../widgets/where_step.dart';

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
          ..showSnackBar(SnackBar(content: Text(editing ? 'Changes saved.' : 'Snag filed.')));
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
      appBar: AppBar(title: Text(editing ? 'EDIT SNAG' : 'FILE A SNAG', style: Snag.label(size: 14))),
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

  Widget _primary(bool last, ReportFormState form, ReportFormController ctrl, bool editing) {
    if (!last) return InkButton(key: K.next, label: 'NEXT', onPressed: ctrl.next);
    if (form.error != null) {
      return InkButton(key: K.submitRetry, label: 'RETRY', accent: true, loading: form.submitting, onPressed: ctrl.submit);
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
