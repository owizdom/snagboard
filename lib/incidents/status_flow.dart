import 'incident.dart';

/// The statuses staff may move a snag to from [from].
///
/// submitted    -> acknowledged | inProgress | declined
/// acknowledged -> inProgress | declined
/// inProgress   -> resolved
/// resolved     -> inProgress   (reopen when the fix did not hold)
/// declined     -> acknowledged (reopen)
List<IncidentStatus> nextStatuses(IncidentStatus from) => switch (from) {
  IncidentStatus.submitted => const [
    IncidentStatus.acknowledged,
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  ],
  IncidentStatus.acknowledged => const [
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  ],
  IncidentStatus.inProgress => const [IncidentStatus.resolved],
  IncidentStatus.resolved => const [IncidentStatus.inProgress],
  IncidentStatus.declined => const [IncidentStatus.acknowledged],
};

bool canTransition(IncidentStatus from, IncidentStatus to) =>
    nextStatuses(from).contains(to);
