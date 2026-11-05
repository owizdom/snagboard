import 'package:flutter/material.dart';

import '../../incidents/incident_providers.dart';
import '../widgets/screen_header.dart';
import '../widgets/snag_list_view.dart';

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
