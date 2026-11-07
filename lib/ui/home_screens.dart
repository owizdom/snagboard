import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/state/auth_state.dart';
import 'package:snagboard/state/incident_state.dart';
import 'package:snagboard/ui/detail_screen.dart';
import 'package:snagboard/ui/file_snag_screen.dart';
import 'package:snagboard/ui/profile_screens.dart';
import 'package:snagboard/ui/theme.dart';
import 'package:snagboard/ui/ticket.dart';
import 'package:snagboard/ui/widgets.dart';

/// Student tabs: BOARD, MINE, ME. Staff tabs: QUEUE, BOARD, ME.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentUserProvider).value?.isStaff ?? false;
    final tabs = staff
        ? [
            (K.tabQueue, 'QUEUE', const StaffQueueScreen()),
            (K.tabBoard, 'BOARD', const BoardScreen()),
            (K.tabMe, 'ME', const ProfileScreen()),
          ]
        : [
            (K.tabBoard, 'BOARD', const BoardScreen()),
            (K.tabMine, 'MINE', const MineScreen()),
            (K.tabMe, 'ME', const ProfileScreen()),
          ];
    return Scaffold(
      body: tabs[_index].$3,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Snag.paper,
          border: Border(top: Snag.border),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var n = 0; n < tabs.length; n++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: n == _index,
                    label: tabs[n].$2,
                    excludeSemantics: true,
                    child: InkWell(
                      key: tabs[n].$1,
                      onTap: () => setState(() => _index = n),
                      splashFactory: NoSplash.splashFactory,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: n == _index
                                  ? Snag.ink
                                  : Colors.transparent,
                              width: 6,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[n].$2,
                          style: Snag.label(
                            size: 13,
                            color: n == _index ? Snag.ink : Snag.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everyone's snags, with a slab to file a new one.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SnagListView(
          scope: FilterScope.board,
          emptyTitle: 'NOTHING ON THE BOARD',
          emptyMessage: 'No snags yet. File the first one.',
          header: const _BoardHeader(),
        ),
      ),
    );
  }
}

/// Title with the live open count, and the FILE A SNAG slab. Its own widget
/// so the count keeps updating while another screen covers the board.
class _BoardHeader extends ConsumerWidget {
  const _BoardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(incidentsProvider).value;
    final open = all == null ? null : countByGroup(all)[StatusGroup.open];
    return ScreenHeader(
      title: 'CAMPUS BOARD',
      subtitle: open == null ? 'LOADING' : '$open OPEN SNAGS',
      child: InkWell(
        key: K.fileSnag,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const FileSnagScreen())),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Snag.ink,
            borderRadius: BorderRadius.circular(Snag.radius),
          ),
          child: Text(
            'FILE A SNAG',
            style: Snag.label(size: 15, color: Snag.paper),
          ),
        ),
      ),
    );
  }
}

/// The snags the signed-in user filed.
class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: SnagListView(
        scope: FilterScope.mine,
        ownCountsOnly: true,
        emptyTitle: 'NOTHING FILED YET',
        emptyMessage: 'Snags you file show up here with their status.',
        header: ScreenHeader(title: 'MY SNAGS', subtitle: 'FILED BY YOU'),
      ),
    ),
  );
}

/// Staff triage: urgent first, then most affected, then oldest. The ribbon
/// switches between open, active and closed snags.
class StaffQueueScreen extends StatelessWidget {
  const StaffQueueScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: SnagListView(
        scope: FilterScope.queue,
        emptyTitle: 'QUEUE CLEAR',
        emptyMessage: 'No snags in this group.',
        header: ScreenHeader(
          title: 'STAFF QUEUE',
          subtitle: 'URGENT FIRST, THEN MOST AFFECTED, THEN OLDEST',
        ),
      ),
    ),
  );
}

/// The list used by BOARD, MINE and QUEUE: a header, the status ribbon,
/// search, category chips and the tickets (or loading / error / empty).
class SnagListView extends ConsumerStatefulWidget {
  const SnagListView({
    super.key,
    required this.scope,
    required this.header,
    required this.emptyTitle,
    required this.emptyMessage,
    this.ownCountsOnly = false,
  });

  final FilterScope scope;
  final Widget header;
  final String emptyTitle;
  final String emptyMessage;

  /// Ribbon counts only the signed-in user's snags (MINE and ME).
  final bool ownCountsOnly;

  @override
  ConsumerState<SnagListView> createState() => _SnagListViewState();
}

class _SnagListViewState extends ConsumerState<SnagListView> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(filterProvider(widget.scope)).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    final n = ref.read(filterProvider(widget.scope).notifier);
    _search.clear();
    n.setQuery('');
    n.clearCategories();
    n.setGroup(StatusGroup.all);
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final filter = ref.watch(filterProvider(scope));
    final notifier = ref.read(filterProvider(scope).notifier);
    final all = ref.watch(incidentsProvider);
    final uid = ref.watch(currentUserProvider).value?.uid ?? '';
    final list = ref.watch(filteredIncidentsProvider(scope));
    const pad = EdgeInsets.symmetric(horizontal: 16);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: widget.header),
        if (all.hasValue)
          SliverPadding(
            padding: pad.copyWith(top: 12),
            sliver: SliverToBoxAdapter(
              child: StatusRibbon(
                counts: countByGroup(
                  widget.ownCountsOnly
                      ? all.requireValue
                            .where((i) => i.reporterId == uid)
                            .toList()
                      : all.requireValue,
                ),
                selected: filter.group,
                onSelect: notifier.setGroup,
              ),
            ),
          ),
        SliverPadding(
          padding: pad.copyWith(top: 12),
          sliver: SliverToBoxAdapter(
            child: TextField(
              key: K.search,
              controller: _search,
              onChanged: notifier.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search title, place or code',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _chips(filter, notifier)),
        ...list.when(
          loading: () => [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                key: K.listLoading,
                child: CircularProgressIndicator(),
              ),
            ),
          ],
          error: (e, _) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorPanel(
                key: K.listError,
                retryKey: K.listRetry,
                message: 'The board could not be loaded.',
                onRetry: () => ref.invalidate(incidentsProvider),
              ),
            ),
          ],
          data: (items) => items.isEmpty ? [_empty(filter)] : [_tickets(items)],
        ),
      ],
    );
  }

  Widget _chips(IncidentFilter filter, FilterNotifier notifier) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Chip(
              label: 'ALL',
              selected: filter.categories.isEmpty,
              onTap: notifier.clearCategories,
            ),
            for (final c in IncidentCategory.values)
              _Chip(
                key: K.categoryChip(c),
                label: c.label.toUpperCase(),
                tooltip: c.label,
                selected: filter.categories.contains(c),
                onTap: () => notifier.toggleCategory(c),
              ),
          ],
        ),
      );

  Widget _empty(IncidentFilter filter) {
    final filtered =
        filter.query.isNotEmpty ||
        filter.categories.isNotEmpty ||
        filter.group != StatusGroup.all;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: filtered
          ? EmptyState(
              key: K.listEmpty,
              title: 'NO MATCHES',
              message: 'No snags fit these filters.',
              action: OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('CLEAR FILTERS'),
              ),
            )
          : EmptyState(
              key: K.listEmpty,
              title: widget.emptyTitle,
              message: widget.emptyMessage,
            ),
    );
  }

  Widget _tickets(List<Incident> items) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    sliver: SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, n) {
        final i = items[n];
        return TicketCard(
          key: K.ticket(i.id),
          incident: i,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => IncidentDetailScreen(incidentId: i.id),
            ),
          ),
        );
      },
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });
  final String label;
  final String? tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Snag.ink : null,
            border: Border.all(color: Snag.ink, width: Snag.outline),
            borderRadius: BorderRadius.circular(Snag.radius),
          ),
          child: Text(
            label,
            style: Snag.label(
              size: 13,
              color: selected ? Snag.paper : Snag.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
