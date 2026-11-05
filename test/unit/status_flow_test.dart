import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/status_flow.dart';

const statuses = IncidentStatus.values;

const allowed = <IncidentStatus, Set<IncidentStatus>>{
  IncidentStatus.submitted: {
    IncidentStatus.acknowledged,
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  },
  IncidentStatus.acknowledged: {
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  },
  IncidentStatus.inProgress: {IncidentStatus.resolved},
  IncidentStatus.resolved: {IncidentStatus.inProgress},
  IncidentStatus.declined: {IncidentStatus.acknowledged},
};

void main() {
  group('canTransition over the full 5x5 grid', () {
    for (final from in statuses) {
      for (final to in statuses) {
        final ok = allowed[from]!.contains(to);
        test(
          '${from.name} -> ${to.name} is ${ok ? 'allowed' : 'refused'}',
          () => expect(canTransition(from, to), ok),
        );
      }
    }
  });

  group('nextStatuses', () {
    for (final from in statuses) {
      test('from ${from.name}', () {
        final next = nextStatuses(from);
        expect(next.toSet(), allowed[from]);
        expect(next.length, allowed[from]!.length, reason: 'no duplicates');
      });
    }
  });

  test('nextStatuses agrees with canTransition', () {
    for (final from in statuses) {
      for (final to in statuses) {
        expect(nextStatuses(from).contains(to), canTransition(from, to));
      }
    }
  });
}
