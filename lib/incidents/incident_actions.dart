import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../core/validators.dart';
import 'incident.dart';
import 'incident_providers.dart';
import 'status_flow.dart';

/// Status changes, "affects me too" and deletes, with AsyncValue state so
/// screens can show progress and errors. The acting user comes from
/// `currentUserProvider`.
class IncidentActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Staff only. Throws [StateError] if the transition is not allowed or
  /// the note is invalid.
  Future<void> changeStatus(
    Incident incident,
    IncidentStatus to,
    String note,
  ) async {
    if (!canTransition(incident.status, to)) {
      throw StateError(
        'Cannot move from ${incident.status.wire} to ${to.wire}',
      );
    }
    final noteError = validateNote(note);
    if (noteError != null) throw StateError(noteError);
    final user = ref.read(currentUserProvider).value;
    if (user == null) throw StateError('Not signed in');
    await _run(
      () => ref
          .read(incidentRepositoryProvider)
          .changeStatus(incident, to, note.trim(), user),
    );
  }

  /// Flips the current user's "affects me too" on [incident].
  Future<void> toggleAffected(Incident incident) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) throw StateError('Not signed in');
    final affected = !incident.affectedBy.contains(user.uid);
    return _run(
      () => ref
          .read(incidentRepositoryProvider)
          .setAffected(incident.id, user.uid, affected),
    );
  }

  Future<void> delete(Incident incident) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) throw StateError('Not signed in');
    return _run(
      () => ref
          .read(incidentRepositoryProvider)
          .delete(incident, callerUid: user.uid),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

final incidentActionsProvider = AsyncNotifierProvider<IncidentActions, void>(
  IncidentActions.new,
);
