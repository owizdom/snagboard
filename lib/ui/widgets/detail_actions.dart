import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/app_user.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_actions.dart';
import '../../incidents/status_flow.dart';
import '../keys.dart';
import '../screens/file_snag_screen.dart';
import 'ink_field.dart';
import 'messages.dart';
import 'status_note_sheet.dart';

/// Everything the viewer may do to this snag: "affects me too", edit and
/// withdraw (owner, while submitted), move and delete (staff).
class DetailActions extends ConsumerWidget {
  const DetailActions({super.key, required this.incident, required this.user});
  final Incident incident;
  final AppUser user;

  bool get _isOwner => incident.reporterId == user.uid;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, {bool pop = false}) async {
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final err = await runAction(container, action, (c) => c.read(incidentActionsProvider));
    if (err != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
    } else if (pop && navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String title, String message) async {
    final actions = ref.read(incidentActionsProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Snag.paper,
        shape: Snag.shape,
        title: Text(title, style: Snag.label(size: 14)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
          TextButton(
            key: K.confirmDelete,
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Snag.danger),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, ref, () => actions.delete(incident), pop: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(incidentActionsProvider.notifier);
    final affected = incident.affectedBy.contains(user.uid);
    final canOwnerAct = _isOwner && incident.status == IncidentStatus.submitted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isOwner) ...[
          const SectionLabel('SAME PROBLEM?'),
          OutlinedButton(
            key: K.affectsToggle,
            onPressed: () => _run(context, ref, () => actions.toggleAffected(incident)),
            child: Text(affected
                ? 'YOU ARE COUNTED (${incident.affectedBy.length}). TAP TO UNDO'
                : 'AFFECTS ME TOO (${incident.affectedBy.length})'),
          ),
        ],
        if (canOwnerAct) ...[
          const SectionLabel('YOUR SNAG'),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                key: K.edit,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => FileSnagScreen(editing: incident)),
                ),
                child: const Text('EDIT'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                key: K.withdraw,
                onPressed: () => _delete(context, ref, 'WITHDRAW THIS SNAG?', 'It is removed from the board for good.'),
                child: const Text('WITHDRAW'),
              ),
            ),
          ]),
        ],
        if (user.isStaff) ...[
          const SectionLabel('MOVE TO'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in nextStatuses(incident.status))
              OutlinedButton(
                key: K.moveTo(s),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Snag.paper,
                  shape: const RoundedRectangleBorder(
                    side: Snag.border,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Snag.radius)),
                  ),
                  builder: (_) => StatusNoteSheet(incident: incident, to: s),
                ),
                child: Text(s.label.toUpperCase(), style: TextStyle(color: Snag.statusColor(s))),
              ),
          ]),
          const SizedBox(height: 12),
          TextButton(
            key: K.staffDelete,
            onPressed: () => _delete(context, ref, 'DELETE THIS SNAG?', 'Use this for spam or duplicates. It cannot be undone.'),
            style: TextButton.styleFrom(foregroundColor: Snag.danger),
            child: const Text('DELETE SNAG'),
          ),
        ],
      ],
    );
  }
}
