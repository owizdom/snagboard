import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../incidents/incident.dart';
import '../../incidents/incident_filter.dart';
import '../../incidents/incident_providers.dart';
import '../keys.dart';
import '../widgets/screen_header.dart';
import '../widgets/snag_list_view.dart';
import 'file_snag_screen.dart';

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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FileSnagScreen()),
        ),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Snag.ink,
            borderRadius: BorderRadius.circular(Snag.radius),
          ),
          child: Text('FILE A SNAG', style: Snag.label(size: 15, color: Snag.paper)),
        ),
      ),
    );
  }
}
