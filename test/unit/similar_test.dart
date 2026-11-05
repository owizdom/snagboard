import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/similar.dart';

import '../fakes/fakes.dart';

void main() {
  test('finds open snags with the same category and location only', () {
    final all = [
      makeIncident(id: 'aaaa0001', category: IncidentCategory.water),
      makeIncident(
        id: 'bbbb0002',
        category: IncidentCategory.water,
        status: IncidentStatus.resolved,
      ),
      makeIncident(id: 'cccc0003', category: IncidentCategory.electricity),
      makeIncident(
        id: 'dddd0004',
        category: IncidentCategory.water,
        location: 'Library',
      ),
    ];
    final r = findSimilar(all, IncidentCategory.water, 'Student Residence A');
    expect(r.map((i) => i.id), ['aaaa0001']);
  });
}
