import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/incident_repository.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/state/auth_state.dart';
import 'package:snagboard/state/report_form.dart';

/// The Firebase implementations, provided once and shared app-wide.
final photoStoreProvider = Provider<PhotoStore>((ref) => FirebasePhotoStore());

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => FirestoreIncidentRepository(photos: ref.watch(photoStoreProvider)),
);

/// The single Firestore listener every screen reads from. It restarts for
/// each signed-in user, so a listener refused at sign-out never carries its
/// error over to the next account.
final incidentsProvider = StreamProvider<List<Incident>>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.value?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchAll();
});

/// Derived from [incidentsProvider], so the board and the details screen
/// can never disagree about a snag.
final incidentByIdProvider = Provider.family<AsyncValue<Incident?>, String>((
  ref,
  id,
) {
  return ref.watch(incidentsProvider).whenData((all) {
    for (final i in all) {
      if (i.id == id) return i;
    }
    return null;
  });
});

enum FilterScope { board, mine, queue }

class FilterNotifier extends Notifier<IncidentFilter> {
  FilterNotifier(this.scope);
  final FilterScope scope;

  @override
  IncidentFilter build() => switch (scope) {
    FilterScope.board => const IncidentFilter(),
    FilterScope.mine => const IncidentFilter(mineOnly: true),
    FilterScope.queue => const IncidentFilter(
      group: StatusGroup.open,
      sort: SortOrder.triage,
    ),
  };

  void setQuery(String q) => state = state.copyWith(query: q);
  void setGroup(StatusGroup g) => state = state.copyWith(group: g);
  void setSort(SortOrder s) => state = state.copyWith(sort: s);

  void toggleCategory(IncidentCategory c) {
    final next = {...state.categories};
    if (!next.remove(c)) next.add(c);
    state = state.copyWith(categories: next);
  }

  void clearCategories() => state = state.copyWith(categories: {});
}

final filterProvider =
    NotifierProvider.family<FilterNotifier, IncidentFilter, FilterScope>(
      FilterNotifier.new,
    );

final filteredIncidentsProvider =
    Provider.family<AsyncValue<List<Incident>>, FilterScope>((ref, scope) {
      final filter = ref.watch(filterProvider(scope));
      final uid = ref.watch(currentUserProvider).value?.uid ?? '';
      return ref
          .watch(incidentsProvider)
          .whenData((all) => applyFilter(all, filter, uid: uid));
    });

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

/// Open snags (submitted or acknowledged) with the same category and the
/// same location, newest first. Used to offer "affects me too" instead of
/// a duplicate report.
List<Incident> findSimilar(
  List<Incident> all,
  IncidentCategory category,
  String location,
) =>
    all
        .where(
          (i) => i.isOpen && i.category == category && i.location == location,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
