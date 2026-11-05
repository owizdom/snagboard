import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'incident.dart';

/// Status changes, "affects me too" and deletes, with AsyncValue state so
/// screens can show progress and errors. The acting user comes from
/// `currentUserProvider`.
class IncidentActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Staff only. Throws [StateError] if the transition is not allowed or
  /// the note is invalid.
  Future<void> changeStatus(Incident incident, IncidentStatus to, String note) =>
      throw UnimplementedError();

  /// Flips the current user's "affects me too" on [incident].
  Future<void> toggleAffected(Incident incident) => throw UnimplementedError();

  Future<void> delete(Incident incident) => throw UnimplementedError();
}

final incidentActionsProvider =
    AsyncNotifierProvider<IncidentActions, void>(IncidentActions.new);
