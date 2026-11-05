import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_filter.dart';

import '../fakes/fakes.dart';

void main() {
  final all = [
    makeIncident(
      id: 'aaaa0001',
      title: 'Leaking Tap',
      category: IncidentCategory.water,
      status: IncidentStatus.submitted,
    ),
    makeIncident(
      id: 'bbbb0002',
      title: 'Dead socket',
      category: IncidentCategory.electricity,
      status: IncidentStatus.resolved,
    ),
  ];

  List<String> run(IncidentFilter f) =>
      applyFilter(all, f, uid: 'stu1').map((i) => i.id).toList();

  test('search matches the title, ignoring case', () {
    expect(run(const IncidentFilter(query: 'leaking')), ['aaaa0001']);
  });

  test('a category filter keeps only that category', () {
    expect(
      run(const IncidentFilter(categories: {IncidentCategory.electricity})),
      ['bbbb0002'],
    );
  });

  test('a status group keeps only snags in that group', () {
    expect(run(const IncidentFilter(group: StatusGroup.closed)), ['bbbb0002']);
  });
}
