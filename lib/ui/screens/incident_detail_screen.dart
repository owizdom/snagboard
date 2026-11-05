import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_providers.dart';
import '../keys.dart';
import '../widgets/detail_actions.dart';
import '../widgets/detail_photo.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_panel.dart';
import '../widgets/ink_field.dart';
import '../widgets/status_stamp.dart';
import '../widgets/status_track.dart';

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
              ? const EmptyState(title: 'THIS SNAG WAS REMOVED', message: 'It may have been withdrawn or deleted.')
              : _Content(incident: i, viewerIsStaff: user?.isStaff ?? false, viewerId: user?.uid, actions: user == null
                  ? const SizedBox.shrink()
                  : DetailActions(incident: i, user: user)),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.incident, required this.viewerIsStaff, required this.viewerId, required this.actions});
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
        Row(children: [
          Expanded(child: Text(i.ticketCode, style: Snag.label(size: 30))),
          StatusStamp(key: K.detailStamp, status: i.status, size: 13),
        ]),
        const SizedBox(height: 12),
        Text(i.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.15)),
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
            SizedBox(width: 104, child: Text(label, style: Snag.label(size: 11, color: Snag.inkSoft))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );
}
