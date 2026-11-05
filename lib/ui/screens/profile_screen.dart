import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/app_user.dart';
import '../../auth/auth_controller.dart';
import '../../auth/auth_providers.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_providers.dart';
import '../keys.dart';
import '../widgets/avatar.dart';
import '../widgets/error_panel.dart';
import '../widgets/ink_button.dart';
import '../widgets/ink_field.dart';
import '../widgets/status_stamp.dart';
import '../widgets/ticket_card.dart';
import 'edit_profile_screen.dart';
import 'incident_detail_screen.dart';

/// ME: who you are, an incident summary, your recent snags, edit and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final incidents = ref.watch(incidentsProvider);

    return Scaffold(
      body: SafeArea(
        child: incidents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorPanel(
            message: 'Could not load your profile.',
            onRetry: () => ref.invalidate(incidentsProvider),
          ),
          data: (all) => user == null
              ? const Center(child: CircularProgressIndicator())
              : _content(context, ref, user, all),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, AppUser user, List<Incident> all) {
    // Students count their own snags; staff count every snag.
    final snags = user.isStaff ? all : all.where((i) => i.reporterId == user.uid).toList();

    int countOf(List<IncidentStatus> statuses) =>
        snags.where((i) => statuses.contains(i.status)).length;
    final open = countOf([IncidentStatus.submitted, IncidentStatus.acknowledged]);
    final active = countOf([IncidentStatus.inProgress]);
    final resolved = countOf([IncidentStatus.resolved]);

    // Students: newest filed first. Staff: most recently updated first.
    final sorted = [...snags];
    if (user.isStaff) {
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final recent = sorted.take(3).toList();

    final emptyProgramme = user.isStaff ? 'Add your department' : 'Add your degree';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(key: K.avatar, user: user),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: Snag.label(size: 12, color: Snag.inkSoft)),
                  const SizedBox(height: 10),
                  Stamp(
                    key: K.roleStamp,
                    label: user.isStaff ? 'STAFF' : 'STUDENT',
                    color: user.isStaff ? Snag.statusColor(IncidentStatus.acknowledged) : Snag.ink,
                    size: 13,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          key: K.programme,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(user.programme ?? emptyProgramme, style: const TextStyle(fontSize: 16))],
        ),
        const SectionLabel('INCIDENT REPORTS'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Snag.ink, width: Snag.outline),
            borderRadius: BorderRadius.circular(Snag.radius),
          ),
          child: Row(
            children: [
              _number('total', 'TOTAL', snags.length),
              _number('open', 'OPEN', open),
              _number('active', 'IN PROGRESS', active),
              _number('resolved', 'RESOLVED', resolved),
            ],
          ),
        ),
        const SectionLabel('RECENT'),
        Column(
          key: K.recentList,
          children: [
            if (recent.isEmpty) const Text('Nothing here yet.'),
            for (final i in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TicketCard(
                  key: K.ticket(i.id),
                  incident: i,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => IncidentDetailScreen(incidentId: i.id)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: K.editProfile,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()),
          ),
          child: const Text('EDIT PROFILE'),
        ),
        const SizedBox(height: 12),
        InkButton(
          key: K.signOut,
          label: 'SIGN OUT',
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }

  /// One labelled number in the summary box.
  Widget _number(String name, String label, int value) => Expanded(
    child: Column(
      key: K.summary(name),
      children: [
        Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: Snag.label(size: 10, color: Snag.inkSoft)),
      ],
    ),
  );
}
