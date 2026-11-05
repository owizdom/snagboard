import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../incidents/incident_providers.dart';
import '../../incidents/report_form_controller.dart';
import '../keys.dart';
import 'ink_field.dart';

/// Step 3: title, description, optional photo, and the anonymous switch.
class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({super.key});

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final _title = TextEditingController(text: ref.read(reportFormProvider).draft.title);
  late final _description = TextEditingController(text: ref.read(reportFormProvider).draft.description);

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
                  errorBuilder: (_, _, _) => const Center(child: Icon(Icons.image_outlined)),
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
          title: const Text('Hide my name from other students; staff still see it'),
          value: form.draft.anonymous,
          onChanged: ctrl.setAnonymous,
        ),
      ],
    );
  }
}
