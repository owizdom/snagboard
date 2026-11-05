import 'incident.dart';

/// The statuses staff may move a snag to from [from].
///
/// submitted    -> acknowledged | inProgress | declined
/// acknowledged -> inProgress | declined
/// inProgress   -> resolved
/// resolved     -> inProgress   (reopen when the fix did not hold)
/// declined     -> acknowledged (reopen)
List<IncidentStatus> nextStatuses(IncidentStatus from) =>
    throw UnimplementedError();

bool canTransition(IncidentStatus from, IncidentStatus to) =>
    throw UnimplementedError();
