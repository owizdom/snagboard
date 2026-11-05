import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/similar.dart';

import '../fakes/fakes.dart';

void main() {
  Incident mk(
    String id,
    IncidentCategory c,
    String loc,
    IncidentStatus s, {
    int day = 1,
  }) => makeIncident(
    id: id,
    category: c,
    location: loc,
    status: s,
    createdAt: DateTime(2026, 11, day),
  );

  test('returns only open snags with the same category and location', () {
    final all = [
      mk(
        'aaaa0001',
        IncidentCategory.water,
        'Library',
        IncidentStatus.submitted,
      ),
      mk(
        'bbbb0002',
        IncidentCategory.water,
        'Library',
        IncidentStatus.acknowledged,
      ),
      mk(
        'cccc0003',
        IncidentCategory.water,
        'Library',
        IncidentStatus.inProgress,
      ),
      mk(
        'dddd0004',
        IncidentCategory.water,
        'Library',
        IncidentStatus.resolved,
      ),
      mk(
        'eeee0005',
        IncidentCategory.water,
        'Library',
        IncidentStatus.declined,
      ),
      mk(
        'ffff0006',
        IncidentCategory.electricity,
        'Library',
        IncidentStatus.submitted,
      ),
      mk(
        'gggg0007',
        IncidentCategory.water,
        'Cafeteria',
        IncidentStatus.submitted,
      ),
    ];
    final r = findSimilar(all, IncidentCategory.water, 'Library');
    expect(r.map((i) => i.id).toSet(), {'aaaa0001', 'bbbb0002'});
  });

  test('empty when nothing matches', () {
    final all = [
      mk(
        'aaaa0001',
        IncidentCategory.water,
        'Library',
        IncidentStatus.submitted,
      ),
    ];
    expect(findSimilar(all, IncidentCategory.safety, 'Library'), isEmpty);
    expect(findSimilar(all, IncidentCategory.water, 'Parking'), isEmpty);
    expect(findSimilar(const [], IncidentCategory.water, 'Library'), isEmpty);
  });

  test('newest first', () {
    final all = [
      mk(
        'aaaa0001',
        IncidentCategory.water,
        'Library',
        IncidentStatus.submitted,
        day: 1,
      ),
      mk(
        'bbbb0002',
        IncidentCategory.water,
        'Library',
        IncidentStatus.submitted,
        day: 3,
      ),
      mk(
        'cccc0003',
        IncidentCategory.water,
        'Library',
        IncidentStatus.submitted,
        day: 2,
      ),
    ];
    expect(
      findSimilar(all, IncidentCategory.water, 'Library').map((i) => i.id),
      ['bbbb0002', 'cccc0003', 'aaaa0001'],
    );
  });
}
