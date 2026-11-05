import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../core/campus.dart';
import '../../core/validators.dart';
import '../../incidents/incident_providers.dart';
import '../keys.dart';
import '../widgets/avatar.dart';
import '../widgets/ink_button.dart';
import '../widgets/ink_field.dart';
import '../widgets/screen_header.dart';

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
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _changePhoto() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final path = await ref.read(photoPickerProvider).pick(fromCamera: false);
      if (path != null) {
        await ref.read(profileRepositoryProvider).setPhoto(user.uid, path);
        if (!mounted) return;
        _showMessage('Photo updated.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not change the photo. Try again.');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .update(user.uid, displayName: _name.text, programme: _programme);
      if (!mounted) return;
      _showMessage('Profile saved.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage('Could not save your profile. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
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
            Align(alignment: Alignment.centerLeft, child: Avatar(user: user)),
            const SizedBox(height: 12),
            InkButton(
              key: K.editPhoto,
              label: 'CHANGE PHOTO',
              loading: _busy,
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
                    initialValue: options.contains(_programme) ? _programme : null,
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
            InkButton(key: K.editSave, label: 'SAVE', accent: true, loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
