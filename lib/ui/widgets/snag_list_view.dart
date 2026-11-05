import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_filter.dart';
import '../../incidents/incident_providers.dart';
import '../keys.dart';
import '../screens/incident_detail_screen.dart';
import 'empty_state.dart';
import 'error_panel.dart';
import 'status_ribbon.dart';
import 'ticket_card.dart';

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
    _search = TextEditingController(text: ref.read(filterProvider(widget.scope)).query);
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
                counts: countByGroup(widget.ownCountsOnly
                    ? all.requireValue.where((i) => i.reporterId == uid).toList()
                    : all.requireValue),
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
              child: Center(key: K.listLoading, child: CircularProgressIndicator()),
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

  Widget _chips(IncidentFilter filter, FilterNotifier notifier) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Chip(label: 'ALL', selected: filter.categories.isEmpty, onTap: notifier.clearCategories),
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
    final filtered = filter.query.isNotEmpty ||
        filter.categories.isNotEmpty ||
        filter.group != StatusGroup.all;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: filtered
          ? EmptyState(
              key: K.listEmpty,
              title: 'NO MATCHES',
              message: 'No snags fit these filters.',
              action: OutlinedButton(onPressed: _clearFilters, child: const Text('CLEAR FILTERS')),
            )
          : EmptyState(key: K.listEmpty, title: widget.emptyTitle, message: widget.emptyMessage),
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
                MaterialPageRoute<void>(builder: (_) => IncidentDetailScreen(incidentId: i.id)),
              ),
            );
          },
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.selected, required this.onTap, this.tooltip});
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
              child: Text(label, style: Snag.label(size: 13, color: selected ? Snag.paper : Snag.ink)),
            ),
          ),
        ),
      );
}
