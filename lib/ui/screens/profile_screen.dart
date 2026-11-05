import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_providers.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_filter.dart';
import '../../incidents/incident_providers.dart';
import '../keys.dart';
import '../widgets/ink_button.dart';
import '../widgets/ink_field.dart';
import '../widgets/screen_header.dart';
import '../widgets/status_stamp.dart';

/// ME: who you are, your role, your own counts, and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final all = ref.watch(incidentsProvider).value ?? const <Incident>[];
    final counts = countByGroup(all.where((i) => i.reporterId == user?.uid).toList());
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenHeader(title: user?.displayName ?? '', subtitle: user?.email),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stamp(
                  key: K.roleStamp,
                  label: (user?.isStaff ?? false) ? 'STAFF' : 'STUDENT',
                  color: (user?.isStaff ?? false) ? Snag.statusColor(IncidentStatus.acknowledged) : Snag.ink,
                  size: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('SNAGS YOU FILED'),
                  Text(
                    'OPEN ${counts[StatusGroup.open]}   ACTIVE ${counts[StatusGroup.active]}   CLOSED ${counts[StatusGroup.closed]}',
                    style: Snag.label(size: 13),
                  ),
                  const SectionLabel('HOW ROLES WORK'),
                  const Text(
                    'Staff are appointed by the campus admin in the console. Students file snags and can say '
                    '"affects me too", but only staff can move a snag to a new status.',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  InkButton(
                    key: K.signOut,
                    label: 'SIGN OUT',
                    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
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
