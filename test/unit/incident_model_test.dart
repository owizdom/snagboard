import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';

import '../fakes/fakes.dart';

void main() {
  test('a snag survives toMap and fromMap unchanged', () {
    final i = makeIncident(
      id: 'abcd1234',
      category: IncidentCategory.electricity,
      urgency: Urgency.urgent,
      status: IncidentStatus.inProgress,
      affectedBy: ['u1', 'u2'],
    );
    final back = Incident.fromMap(i.id, i.toMap());
    expect(back.title, i.title);
    expect(back.category, i.category);
    expect(back.urgency, i.urgency);
    expect(back.status, i.status);
    expect(back.affectedBy, i.affectedBy);
    expect(back.createdAt, i.createdAt);
    expect(back.history.length, i.history.length);
  });
}
