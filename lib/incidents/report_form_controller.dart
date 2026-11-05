import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'incident.dart';

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
  }) =>
      ReportFormState(
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

  void startEdit(Incident incident) => throw UnimplementedError();

  void setCategory(IncidentCategory c) => throw UnimplementedError();
  void setUrgency(Urgency u) => throw UnimplementedError();
  void setLocation(String location) => throw UnimplementedError();
  void setSpot(String spot) => throw UnimplementedError();
  void setTitle(String title) => throw UnimplementedError();
  void setDescription(String description) => throw UnimplementedError();
  void setAnonymous(bool anonymous) => throw UnimplementedError();
  void setPhoto(String? localPath) => throw UnimplementedError();

  /// Returns true when the step was valid and the form advanced.
  bool next() => throw UnimplementedError();
  void back() => throw UnimplementedError();

  Future<void> submit() => throw UnimplementedError();
}

final reportFormProvider =
    NotifierProvider.autoDispose<ReportFormController, ReportFormState>(
  ReportFormController.new,
);
