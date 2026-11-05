import 'incident.dart';

/// newest: most recent first. mostAffected: most "affects me too" first,
/// newest breaks ties. triage: urgent first, then most affected, then
/// oldest first.
enum SortOrder { newest, mostAffected, triage }

class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.categories = const {},
    this.group = StatusGroup.all,
    this.mineOnly = false,
    this.sort = SortOrder.newest,
  });

  final String query;

  /// Empty means every category.
  final Set<IncidentCategory> categories;
  final StatusGroup group;
  final bool mineOnly;
  final SortOrder sort;

  IncidentFilter copyWith({
    String? query,
    Set<IncidentCategory>? categories,
    StatusGroup? group,
    bool? mineOnly,
    SortOrder? sort,
  }) => IncidentFilter(
    query: query ?? this.query,
    categories: categories ?? this.categories,
    group: group ?? this.group,
    mineOnly: mineOnly ?? this.mineOnly,
    sort: sort ?? this.sort,
  );
}

/// Which status group a status belongs to (never [StatusGroup.all]).
StatusGroup groupOf(IncidentStatus status) => switch (status) {
  IncidentStatus.submitted || IncidentStatus.acknowledged => StatusGroup.open,
  IncidentStatus.inProgress => StatusGroup.active,
  IncidentStatus.resolved || IncidentStatus.declined => StatusGroup.closed,
};

/// Text search matches title, description, location, spot and ticket code,
/// case-insensitively. All conditions combine with AND. Returns a new list.
List<Incident> applyFilter(
  List<Incident> all,
  IncidentFilter filter, {
  required String uid,
}) {
  final q = filter.query.trim().toLowerCase();

  bool matches(Incident i) {
    if (q.isNotEmpty) {
      final text = [
        i.title,
        i.description,
        i.location,
        i.spot ?? '',
        i.ticketCode,
      ].join('\n').toLowerCase();
      if (!text.contains(q)) return false;
    }
    if (filter.categories.isNotEmpty &&
        !filter.categories.contains(i.category)) {
      return false;
    }
    if (filter.group != StatusGroup.all && groupOf(i.status) != filter.group) {
      return false;
    }
    if (filter.mineOnly && i.reporterId != uid) return false;
    return true;
  }

  int newestFirst(Incident a, Incident b) => b.createdAt.compareTo(a.createdAt);

  final result = all.where(matches).toList();
  switch (filter.sort) {
    case SortOrder.newest:
      result.sort(newestFirst);
    case SortOrder.mostAffected:
      result.sort((a, b) {
        final byCount = b.affectedBy.length.compareTo(a.affectedBy.length);
        return byCount != 0 ? byCount : newestFirst(a, b);
      });
    case SortOrder.triage:
      result.sort((a, b) {
        final aUrgent = a.urgency == Urgency.urgent ? 0 : 1;
        final bUrgent = b.urgency == Urgency.urgent ? 0 : 1;
        if (aUrgent != bUrgent) return aUrgent.compareTo(bUrgent);
        final byCount = b.affectedBy.length.compareTo(a.affectedBy.length);
        if (byCount != 0) return byCount;
        return a.createdAt.compareTo(b.createdAt);
      });
  }
  return result;
}

/// Counts for open, active and closed, plus [StatusGroup.all] = total.
Map<StatusGroup, int> countByGroup(List<Incident> all) {
  final counts = {
    StatusGroup.all: all.length,
    StatusGroup.open: 0,
    StatusGroup.active: 0,
    StatusGroup.closed: 0,
  };
  for (final i in all) {
    final g = groupOf(i.status);
    counts[g] = counts[g]! + 1;
  }
  return counts;
}
