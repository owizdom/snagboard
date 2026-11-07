import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'firebase_photo_store.dart';
import 'firestore_incident_repository.dart';
import 'incident.dart';
import 'incident_filter.dart';
import 'incident_repository.dart';
import 'photo_store.dart';

/// Overridden with fakes in tests.
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
