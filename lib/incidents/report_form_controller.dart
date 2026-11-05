import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../core/validators.dart';
import 'incident.dart';
import 'incident_providers.dart';

/// Steps of the filing flow: 0 WHAT, 1 WHERE, 2 DETAILS, 3 REVIEW.
const reportStepCount = 4;

class ReportFormState {
  const ReportFormState({
    this.step = 0,
    this.draft = const IncidentDraft(),
    this.errors = const {},
    this.submitting = false,
    this.progress = 0,
    this.error,
    this.createdId,
    this.editingId,
  });

  final int step;
  final IncidentDraft draft;

  /// Field name -> message. Field names: category, location, title,
  /// description.
  final Map<String, String> errors;
  final bool submitting;

  /// Photo upload progress, 0 to 1.
  final double progress;

  /// Message of the last failed submit; cleared on retry.
  final String? error;

  /// Set when a new snag was created (or the edit was saved).
  final String? createdId;

  /// Non-null when editing an existing snag.
  final String? editingId;

  bool get isEditing => editingId != null;
  bool get done => createdId != null;

  ReportFormState copyWith({
    int? step,
    IncidentDraft? draft,
    Map<String, String>? errors,
    bool? submitting,
    double? progress,
    String? error,
    bool clearError = false,
    String? createdId,
    String? editingId,
  }) => ReportFormState(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    errors: errors ?? this.errors,
    submitting: submitting ?? this.submitting,
    progress: progress ?? this.progress,
    error: clearError ? null : (error ?? this.error),
    createdId: createdId ?? this.createdId,
    editingId: editingId ?? this.editingId,
  );
}

/// Holds the draft while a student files or edits a snag.
///
/// Step validation: step 0 needs a category; step 1 needs a location;
/// step 2 needs a valid title and description (core/validators.dart).
/// `next()` validates the current step, fills `errors` and only advances
/// when it is valid. Changing a field clears that field's error.
/// `submit()` calls `create` (or `updateDetails` when editing) on
/// `incidentRepositoryProvider` with the reporter from
/// `currentUserProvider`, reports upload progress, and on failure keeps
/// the draft and sets `error`.
class ReportFormController extends Notifier<ReportFormState> {
  @override
  ReportFormState build() => const ReportFormState();

  /// Loads an existing snag into the form for editing.
  void startEdit(Incident incident) => state = ReportFormState(
    draft: IncidentDraft.fromIncident(incident),
    editingId: incident.id,
  );

  /// Replaces the draft and clears the error of [field], if any.
  void _update(IncidentDraft draft, [String? field]) {
    final errors = {...state.errors}..remove(field);
    state = state.copyWith(draft: draft, errors: errors);
  }

  void setCategory(IncidentCategory c) =>
      _update(state.draft.copyWith(category: c), 'category');
  void setUrgency(Urgency u) => _update(state.draft.copyWith(urgency: u));
  void setLocation(String location) =>
      _update(state.draft.copyWith(location: location), 'location');
  void setSpot(String spot) => _update(state.draft.copyWith(spot: spot));
  void setTitle(String title) =>
      _update(state.draft.copyWith(title: title), 'title');
  void setDescription(String description) =>
      _update(state.draft.copyWith(description: description), 'description');
  void setAnonymous(bool anonymous) =>
      _update(state.draft.copyWith(anonymous: anonymous));
  void setPhoto(String? localPath) => _update(
    localPath == null
        ? state.draft.copyWith(clearPhoto: true)
        : state.draft.copyWith(photoPath: localPath),
  );

  /// Field errors for the given step (empty map when valid).
  Map<String, String> _validate(int step) {
    final d = state.draft;
    final errors = <String, String>{};
    switch (step) {
      case 0:
        if (d.category == null) errors['category'] = 'Pick a category';
      case 1:
        if ((d.location ?? '').trim().isEmpty) {
          errors['location'] = 'Pick where it is';
        }
      case 2:
        final title = validateTitle(d.title);
        if (title != null) errors['title'] = title;
        final description = validateDescription(d.description);
        if (description != null) errors['description'] = description;
    }
    return errors;
  }

  /// Returns true when the step was valid and the form advanced.
  bool next() {
    final errors = _validate(state.step);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: {...state.errors, ...errors});
      return false;
    }
    if (state.step < reportStepCount - 1) {
      state = state.copyWith(step: state.step + 1);
    }
    return true;
  }

  void back() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  Future<void> submit() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      state = state.copyWith(error: 'You are signed out. Sign in again.');
      return;
    }
    state = state.copyWith(submitting: true, progress: 0, clearError: true);
    try {
      final repo = ref.read(incidentRepositoryProvider);
      final String id;
      if (state.editingId != null) {
        id = state.editingId!;
        await repo.updateDetails(id, state.draft);
      } else {
        id = await repo.create(
          state.draft,
          user,
          onProgress: (p) => state = state.copyWith(progress: p),
        );
      }
      state = state.copyWith(submitting: false, createdId: id);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }
}

final reportFormProvider =
    NotifierProvider.autoDispose<ReportFormController, ReportFormState>(
      ReportFormController.new,
    );
