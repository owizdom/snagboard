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
  }) =>
      IncidentFilter(
        query: query ?? this.query,
        categories: categories ?? this.categories,
        group: group ?? this.group,
        mineOnly: mineOnly ?? this.mineOnly,
        sort: sort ?? this.sort,
      );
}

/// Which status group a status belongs to (never [StatusGroup.all]).
StatusGroup groupOf(IncidentStatus status) => throw UnimplementedError();

/// Text search matches title, description, location, spot and ticket code,
/// case-insensitively. All conditions combine with AND. Returns a new list.
List<Incident> applyFilter(
  List<Incident> all,
  IncidentFilter filter, {
  required String uid,
}) =>
    throw UnimplementedError();

/// Counts for open, active and closed, plus [StatusGroup.all] = total.
Map<StatusGroup, int> countByGroup(List<Incident> all) =>
    throw UnimplementedError();
