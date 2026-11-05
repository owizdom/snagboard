import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/status_flow.dart';

void main() {
  test('a submitted snag can be acknowledged', () {
    expect(
      canTransition(IncidentStatus.submitted, IncidentStatus.acknowledged),
      isTrue,
    );
  });

  test('a submitted snag cannot jump straight to resolved', () {
    expect(
      canTransition(IncidentStatus.submitted, IncidentStatus.resolved),
      isFalse,
    );
  });

  test('nextStatuses lists the allowed moves from in progress', () {
    expect(nextStatuses(IncidentStatus.inProgress), [IncidentStatus.resolved]);
  });
}
