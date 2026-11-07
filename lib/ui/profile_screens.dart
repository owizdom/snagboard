import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/state/auth_state.dart';
import 'package:snagboard/state/incident_state.dart';
import 'package:snagboard/state/report_form.dart';
import 'package:snagboard/ui/detail_screen.dart';
import 'package:snagboard/ui/theme.dart';
import 'package:snagboard/ui/ticket.dart';
import 'package:snagboard/ui/widgets.dart';

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

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    List<Incident> all,
  ) {
    // Students count their own snags; staff count every snag.
    final snags = user.isStaff
        ? all
        : all.where((i) => i.reporterId == user.uid).toList();

    int countOf(List<IncidentStatus> statuses) =>
        snags.where((i) => statuses.contains(i.status)).length;
    final open = countOf([
      IncidentStatus.submitted,
      IncidentStatus.acknowledged,
    ]);
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

    final emptyProgramme = user.isStaff
        ? 'Add your department'
        : 'Add your degree';

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
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Snag.label(size: 12, color: Snag.inkSoft),
                  ),
                  const SizedBox(height: 10),
                  Stamp(
                    key: K.roleStamp,
                    label: user.isStaff ? 'STAFF' : 'STUDENT',
                    color: user.isStaff
                        ? Snag.statusColor(IncidentStatus.acknowledged)
                        : Snag.ink,
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
          children: [
            Text(
              user.programme ?? emptyProgramme,
              style: const TextStyle(fontSize: 16),
            ),
          ],
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
                    MaterialPageRoute<void>(
                      builder: (_) => IncidentDetailScreen(incidentId: i.id),
                    ),
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
        Text(
          '$value',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: Snag.label(size: 10, color: Snag.inkSoft)),
      ],
    ),
  );
}

/// Change your name, degree or department, and profile photo.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _programme;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _changePhoto() async {
    final String? path;
    try {
      path = await ref.read(photoPickerProvider).pick(fromCamera: false);
    } catch (_) {
      _showMessage('Could not open your photos. Try again.');
      return;
    }
    if (path == null) return;
    final ok = await ref
        .read(profileControllerProvider.notifier)
        .setPhoto(path);
    if (!mounted) return;
    _showMessage(
      ok ? 'Photo updated.' : 'Could not change the photo. Try again.',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(profileControllerProvider.notifier)
        .save(displayName: _name.text, programme: _programme);
    if (!mounted) return;
    if (ok) {
      _showMessage('Profile saved.');
      Navigator.of(context).pop();
    } else {
      _showMessage('Could not save your profile. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final busy = ref.watch(profileControllerProvider).isLoading;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Fill the form once, from the saved profile.
    if (!_loaded) {
      _name.text = user.displayName;
      _programme = user.programme;
      _loaded = true;
    }
    final options = user.isStaff ? staffDepartments : studentProgrammes;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const ScreenHeader(title: 'EDIT PROFILE'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Avatar(user: user),
            ),
            const SizedBox(height: 12),
            InkButton(
              key: K.editPhoto,
              label: 'CHANGE PHOTO',
              loading: busy,
              onPressed: _changePhoto,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  InkField(
                    key: K.editName,
                    label: 'FULL NAME',
                    controller: _name,
                    validator: validateName,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: K.editProgramme,
                    initialValue: options.contains(_programme)
                        ? _programme
                        : null,
                    decoration: InputDecoration(
                      labelText: user.isStaff ? 'DEPARTMENT' : 'DEGREE',
                    ),
                    items: [
                      for (final name in options)
                        DropdownMenuItem(
                          key: K.programmeOption(name),
                          value: name,
                          child: Text(name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _programme = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            InkButton(
              key: K.editSave,
              label: 'SAVE',
              accent: true,
              loading: busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
