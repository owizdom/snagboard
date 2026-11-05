import 'package:flutter/material.dart';

import '../../incidents/incident_providers.dart';
import '../widgets/screen_header.dart';
import '../widgets/snag_list_view.dart';

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
