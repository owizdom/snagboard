import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/ui/keys.dart';
import 'package:snagboard/ui/screens/board_screen.dart';

import '../fakes/fakes.dart';

/// Finds a Text under (or at) [key] whose content equals the status label,
/// ignoring case because stamps may print in capitals.
Finder stampShows(Key key, IncidentStatus s, {bool skipOffstage = true}) =>
    find.descendant(
      of: find.byKey(key, skipOffstage: skipOffstage),
      matchRoot: true,
      skipOffstage: skipOffstage,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Text && (w.data ?? '').toLowerCase() == s.label.toLowerCase(),
        skipOffstage: skipOffstage,
      ),
    );

void main() {
  testWidgets(
    'one pushed status change updates the open detail and the board card',
    (t) async {
      t.view.physicalSize = const Size(900, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final original = makeIncident(
        id: 'abcd1234',
        status: IncidentStatus.submitted,
      );
      final h = TestHarness.signedInAs(student, incidents: [original]);
      await t.pumpWidget(h.wrap(const BoardScreen()));
      await t.pumpAndSettle();

      expect(
        stampShows(K.ticketStamp('abcd1234'), IncidentStatus.submitted),
        findsOneWidget,
      );

      await t.tap(find.byKey(K.ticket('abcd1234')));
      await t.pumpAndSettle();
      expect(find.byKey(K.detailStamp), findsOneWidget);
      expect(
        stampShows(K.detailStamp, IncidentStatus.submitted),
        findsOneWidget,
      );

      h.incidents.push(original.copyWith(status: IncidentStatus.inProgress));
      await t.pump();

      expect(
        stampShows(K.detailStamp, IncidentStatus.inProgress),
        findsOneWidget,
        reason: 'detail updates in the same frame',
      );
      expect(stampShows(K.detailStamp, IncidentStatus.submitted), findsNothing);
      expect(
        stampShows(
          K.ticketStamp('abcd1234'),
          IncidentStatus.inProgress,
          skipOffstage: false,
        ),
        findsOneWidget,
        reason: 'board card behind the detail updates in the same frame',
      );

      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await t.pumpAndSettle();

      expect(find.byKey(K.detailStamp), findsNothing);
      expect(
        stampShows(K.ticketStamp('abcd1234'), IncidentStatus.inProgress),
        findsOneWidget,
      );
      expect(
        stampShows(K.ticketStamp('abcd1234'), IncidentStatus.submitted),
        findsNothing,
      );
    },
  );
}
