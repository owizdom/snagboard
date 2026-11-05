import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_actions.dart';
import '../keys.dart';
import 'ink_button.dart';
import 'ink_field.dart';
import 'messages.dart';

/// Bottom sheet where staff write the required note and confirm a move.
class StatusNoteSheet extends ConsumerStatefulWidget {
  const StatusNoteSheet({super.key, required this.incident, required this.to});
  final Incident incident;
  final IncidentStatus to;

  @override
  ConsumerState<StatusNoteSheet> createState() => _StatusNoteSheetState();
}

class _StatusNoteSheetState extends ConsumerState<StatusNoteSheet> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_form.currentState!.validate()) return;
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await runAction(
      container,
      () => ref.read(incidentActionsProvider.notifier).changeStatus(widget.incident, widget.to, _note.text.trim()),
      (c) => c.read(incidentActionsProvider),
    );
    if (err == null) {
      navigator.pop();
    } else if (mounted) {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MOVE TO ${widget.to.label.toUpperCase()}',
                    style: Snag.label(size: 14, color: Snag.statusColor(widget.to))),
                const SizedBox(height: 4),
                const Text('The student sees this note on the ticket log.'),
                const SizedBox(height: 16),
                InkField(
                  key: K.statusNote,
                  label: 'NOTE (REQUIRED)',
                  controller: _note,
                  validator: validateNote,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 280,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Snag.danger, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 8),
                InkButton(key: K.confirmMove, label: 'CONFIRM MOVE', loading: _busy, onPressed: _confirm),
              ],
            ),
          ),
        ),
      );
}
