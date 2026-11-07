import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/state/auth_state.dart';
import 'package:snagboard/state/incident_state.dart';
import 'package:snagboard/state/report_form.dart';
import 'package:snagboard/ui/file_snag_screen.dart';
import 'package:snagboard/ui/theme.dart';
import 'package:snagboard/ui/ticket.dart';
import 'package:snagboard/ui/widgets.dart';

/// One snag: ticket header, details, photo, ticket log and the actions the
/// viewer is allowed. Reads the same provider as the board, so a status
/// change shows up here and there together.
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snag = ref.watch(incidentByIdProvider(incidentId));
    final user = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text('SNAG', style: Snag.label(size: 14))),
      body: SafeArea(
        child: snag.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorPanel(
            message: 'This snag could not be loaded.',
            onRetry: () => ref.invalidate(incidentsProvider),
          ),
          data: (i) => i == null
              ? const EmptyState(
                  title: 'THIS SNAG WAS REMOVED',
                  message: 'It may have been withdrawn or deleted.',
                )
              : _Content(
                  incident: i,
                  viewerIsStaff: user?.isStaff ?? false,
                  viewerId: user?.uid,
                  actions: user == null
                      ? const SizedBox.shrink()
                      : DetailActions(incident: i, user: user),
                ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.incident,
    required this.viewerIsStaff,
    required this.viewerId,
    required this.actions,
  });
  final Incident incident;
  final bool viewerIsStaff;
  final String? viewerId;
  final Widget actions;

  /// Staff still see who filed a hidden-name snag; students never do.
  String _filedBy(WidgetRef ref) {
    if (incident.reporterName != null) return incident.reporterName!;
    if (incident.reporterId == viewerId) return 'You (hidden from students)';
    if (!viewerIsStaff) return 'Hidden from students';
    final name = ref.watch(displayNameProvider(incident.reporterId)).value;
    return '${name ?? 'Loading'} (hidden from students)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = incident;
    final spot = (i.spot == null || i.spot!.isEmpty) ? '' : ', ${i.spot}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: Text(i.ticketCode, style: Snag.label(size: 30))),
            StatusStamp(key: K.detailStamp, status: i.status, size: 13),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          i.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SectionLabel('DETAILS'),
        _Meta('CATEGORY', '${i.category.code}  ${i.category.label}'),
        _Meta('PLACE', '${i.location}$spot'),
        _Meta('URGENCY', i.urgency.label),
        _Meta('FILED BY', _filedBy(ref)),
        _Meta('FILED', formatDateTime(i.createdAt)),
        _Meta('AFFECTS', '${i.affectedBy.length}'),
        const SectionLabel('DESCRIPTION'),
        Text(i.description, style: const TextStyle(fontSize: 16, height: 1.4)),
        if (i.photoUrl != null) ...[
          const SectionLabel('PHOTO'),
          DetailPhoto(url: i.photoUrl!),
        ],
        actions,
        const SectionLabel('TICKET LOG'),
        StatusTrack(key: K.detailTrack, history: i.history),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(label, style: Snag.label(size: 11, color: Snag.inkSoft)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ],
    ),
  );
}

/// Everything the viewer may do to this snag: "affects me too", edit and
/// withdraw (owner, while submitted), move and delete (staff).
class DetailActions extends ConsumerWidget {
  const DetailActions({super.key, required this.incident, required this.user});
  final Incident incident;
  final AppUser user;

  bool get _isOwner => incident.reporterId == user.uid;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    bool pop = false,
  }) async {
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final err = await runAction(
      container,
      action,
      (c) => c.read(incidentActionsProvider),
    );
    if (err != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
    } else if (pop && navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String title,
    String message,
  ) async {
    final actions = ref.read(incidentActionsProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Snag.paper,
        shape: Snag.shape,
        title: Text(title, style: Snag.label(size: 14)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
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
            onPressed: () =>
                _run(context, ref, () => actions.toggleAffected(incident)),
            child: Text(
              affected
                  ? 'YOU ARE COUNTED (${incident.affectedBy.length}). TAP TO UNDO'
                  : 'AFFECTS ME TOO (${incident.affectedBy.length})',
            ),
          ),
        ],
        if (canOwnerAct) ...[
          const SectionLabel('YOUR SNAG'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: K.edit,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FileSnagScreen(editing: incident),
                    ),
                  ),
                  child: const Text('EDIT'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  key: K.withdraw,
                  onPressed: () => _delete(
                    context,
                    ref,
                    'WITHDRAW THIS SNAG?',
                    'It is removed from the board for good.',
                  ),
                  child: const Text('WITHDRAW'),
                ),
              ),
            ],
          ),
        ],
        if (user.isStaff) ...[
          const SectionLabel('MOVE TO'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in nextStatuses(incident.status))
                OutlinedButton(
                  key: K.moveTo(s),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Snag.paper,
                    shape: const RoundedRectangleBorder(
                      side: Snag.border,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(Snag.radius),
                      ),
                    ),
                    builder: (_) => StatusNoteSheet(incident: incident, to: s),
                  ),
                  child: Text(
                    s.label.toUpperCase(),
                    style: TextStyle(color: Snag.statusColor(s)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            key: K.staffDelete,
            onPressed: () => _delete(
              context,
              ref,
              'DELETE THIS SNAG?',
              'Use this for spam or duplicates. It cannot be undone.',
            ),
            style: TextButton.styleFrom(foregroundColor: Snag.danger),
            child: const Text('DELETE SNAG'),
          ),
        ],
      ],
    );
  }
}

/// The snag's photo. Tap to open it full screen and zoom.
class DetailPhoto extends StatelessWidget {
  const DetailPhoto({super.key, required this.url});
  final String url;

  Widget _image(BoxFit fit) => Image.network(
    url,
    fit: fit,
    errorBuilder: (_, _, _) => const SizedBox(
      height: 120,
      child: Center(child: Text('The photo could not be loaded.')),
    ),
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Photo of the problem. Tap to enlarge.',
    child: GestureDetector(
      key: K.detailPhoto,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => Scaffold(
            backgroundColor: Snag.ink,
            appBar: AppBar(
              backgroundColor: Snag.ink,
              foregroundColor: Snag.paper,
            ),
            body: Center(
              child: InteractiveViewer(child: _image(BoxFit.contain)),
            ),
          ),
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Snag.ink, width: Snag.outline),
        ),
        child: _image(BoxFit.cover),
      ),
    ),
  );
}

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
      () => ref
          .read(incidentActionsProvider.notifier)
          .changeStatus(widget.incident, widget.to, _note.text.trim()),
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
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOVE TO ${widget.to.label.toUpperCase()}',
              style: Snag.label(size: 14, color: Snag.statusColor(widget.to)),
            ),
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
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Snag.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            InkButton(
              key: K.confirmMove,
              label: 'CONFIRM MOVE',
              loading: _busy,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    ),
  );
}
