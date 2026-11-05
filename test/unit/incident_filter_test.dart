import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';
import 'package:snagboard/incidents/incident_filter.dart';

import '../fakes/fakes.dart';

List<String> ids(List<Incident> l) => l.map((i) => i.id).toList();

Incident mk(
  String id, {
  String title = 'Some title here',
  String description = 'A long enough description text.',
  String location = 'Library',
  String? spot,
  IncidentCategory category = IncidentCategory.other,
  IncidentStatus status = IncidentStatus.submitted,
  Urgency urgency = Urgency.normal,
  String reporterId = 'stu1',
  List<String> affectedBy = const [],
  int day = 1,
}) => makeIncident(
  id: id,
  title: title,
  description: description,
  location: location,
  spot: spot,
  category: category,
  status: status,
  urgency: urgency,
  reporterId: reporterId,
  affectedBy: affectedBy,
  createdAt: DateTime(2026, 11, day, 9),
);

void main() {
  group('groupOf', () {
    test('mapping', () {
      expect(groupOf(IncidentStatus.submitted), StatusGroup.open);
      expect(groupOf(IncidentStatus.acknowledged), StatusGroup.open);
      expect(groupOf(IncidentStatus.inProgress), StatusGroup.active);
      expect(groupOf(IncidentStatus.resolved), StatusGroup.closed);
      expect(groupOf(IncidentStatus.declined), StatusGroup.closed);
    });
  });

  group('text search', () {
    final all = [
      mk('aaaa0001', title: 'Leaking Tap'),
      mk('bbbb0002', description: 'The projector is BROKEN again'),
      mk('cccc0003', location: 'Cafeteria'),
      mk('dddd0004', spot: 'Room 204'),
      mk('eeee0005'),
    ];
    List<String> q(String s) =>
        ids(applyFilter(all, IncidentFilter(query: s), uid: 'stu1'));

    test('title, case-insensitive', () => expect(q('leaking'), ['aaaa0001']));
    test(
      'description, case-insensitive',
      () => expect(q('broken'), ['bbbb0002']),
    );
    test('location', () => expect(q('CAFETERIA'), ['cccc0003']));
    test('spot', () => expect(q('room 204'), ['dddd0004']));
    test('ticket code', () => expect(q('sng-bbbb'), ['bbbb0002']));
    test('ticket code upper case', () => expect(q('SNG-EEEE'), ['eeee0005']));
    test('no match', () => expect(q('zzzzqqq'), isEmpty));
    test('empty query returns all', () => expect(q('').length, all.length));
  });

  group('filters combine with AND', () {
    final all = [
      mk(
        'aaaa0001',
        category: IncidentCategory.water,
        status: IncidentStatus.submitted,
        reporterId: 'stu1',
      ),
      mk(
        'bbbb0002',
        category: IncidentCategory.water,
        status: IncidentStatus.resolved,
        reporterId: 'stu2',
      ),
      mk(
        'cccc0003',
        category: IncidentCategory.safety,
        status: IncidentStatus.inProgress,
        reporterId: 'stu1',
      ),
      mk(
        'dddd0004',
        category: IncidentCategory.safety,
        status: IncidentStatus.declined,
        reporterId: 'stu1',
      ),
    ];
    List<String> f(IncidentFilter x) =>
        ids(applyFilter(all, x, uid: 'stu1'))..sort();

    test('category set', () {
      expect(f(const IncidentFilter(categories: {IncidentCategory.water})), [
        'aaaa0001',
        'bbbb0002',
      ]);
      expect(
        f(
          const IncidentFilter(
            categories: {IncidentCategory.water, IncidentCategory.safety},
          ),
        ),
        hasLength(4),
      );
    });
    test('groups', () {
      expect(f(const IncidentFilter(group: StatusGroup.open)), ['aaaa0001']);
      expect(f(const IncidentFilter(group: StatusGroup.active)), ['cccc0003']);
      expect(f(const IncidentFilter(group: StatusGroup.closed)), [
        'bbbb0002',
        'dddd0004',
      ]);
      expect(f(const IncidentFilter(group: StatusGroup.all)), hasLength(4));
    });
    test('mineOnly uses uid', () {
      expect(f(const IncidentFilter(mineOnly: true)), [
        'aaaa0001',
        'cccc0003',
        'dddd0004',
      ]);
      expect(
        ids(
          applyFilter(all, const IncidentFilter(mineOnly: true), uid: 'stu2'),
        ),
        ['bbbb0002'],
      );
      expect(
        ids(
          applyFilter(all, const IncidentFilter(mineOnly: true), uid: 'nobody'),
        ),
        isEmpty,
      );
    });
    test('category + group + mine together', () {
      expect(
        f(
          const IncidentFilter(
            categories: {IncidentCategory.safety},
            group: StatusGroup.closed,
            mineOnly: true,
          ),
        ),
        ['dddd0004'],
      );
      expect(
        f(
          const IncidentFilter(
            categories: {IncidentCategory.water},
            group: StatusGroup.closed,
            mineOnly: true,
          ),
        ),
        isEmpty,
      );
    });
    test('query + category together', () {
      expect(
        f(
          const IncidentFilter(
            query: 'sng-bbbb',
            categories: {IncidentCategory.safety},
          ),
        ),
        isEmpty,
      );
      expect(
        f(
          const IncidentFilter(
            query: 'sng-bbbb',
            categories: {IncidentCategory.water},
          ),
        ),
        ['bbbb0002'],
      );
    });
    test('does not mutate the input list', () {
      final copy = ids(all);
      applyFilter(
        all,
        const IncidentFilter(sort: SortOrder.triage),
        uid: 'stu1',
      );
      expect(ids(all), copy);
    });
  });

  group('sort', () {
    test('newest first', () {
      final all = [
        mk('aaaa0001', day: 1),
        mk('bbbb0002', day: 3),
        mk('cccc0003', day: 2),
      ];
      expect(ids(applyFilter(all, const IncidentFilter(), uid: 'x')), [
        'bbbb0002',
        'cccc0003',
        'aaaa0001',
      ]);
    });

    test('mostAffected, ties newest', () {
      final all = [
        mk('aaaa0001', day: 1, affectedBy: ['a']),
        mk('bbbb0002', day: 2, affectedBy: ['a']),
        mk('cccc0003', day: 3),
        mk('dddd0004', day: 1, affectedBy: ['a', 'b', 'c']),
      ];
      expect(
        ids(
          applyFilter(
            all,
            const IncidentFilter(sort: SortOrder.mostAffected),
            uid: 'x',
          ),
        ),
        ['dddd0004', 'bbbb0002', 'aaaa0001', 'cccc0003'],
      );
    });

    test('triage: urgent first, then most affected, then oldest', () {
      final all = [
        mk(
          'aaaa0001',
          day: 5,
          urgency: Urgency.normal,
          affectedBy: ['a', 'b', 'c'],
        ),
        mk('bbbb0002', day: 4, urgency: Urgency.urgent),
        mk('cccc0003', day: 2, urgency: Urgency.urgent, affectedBy: ['a']),
        mk('dddd0004', day: 1, urgency: Urgency.urgent, affectedBy: ['a']),
        mk(
          'eeee0005',
          day: 3,
          urgency: Urgency.normal,
          affectedBy: ['a', 'b', 'c'],
        ),
        mk('ffff0006', day: 6, urgency: Urgency.low),
      ];
      expect(
        ids(
          applyFilter(
            all,
            const IncidentFilter(sort: SortOrder.triage),
            uid: 'x',
          ),
        ),
        [
          'dddd0004',
          'cccc0003',
          'bbbb0002',
          'eeee0005',
          'aaaa0001',
          'ffff0006',
        ],
      );
    });
  });

  group('countByGroup', () {
    test('groups plus all = total', () {
      final all = [
        mk('aaaa0001', status: IncidentStatus.submitted),
        mk('bbbb0002', status: IncidentStatus.acknowledged),
        mk('cccc0003', status: IncidentStatus.inProgress),
        mk('dddd0004', status: IncidentStatus.resolved),
        mk('eeee0005', status: IncidentStatus.declined),
        mk('ffff0006', status: IncidentStatus.declined),
      ];
      final c = countByGroup(all);
      expect(c[StatusGroup.open], 2);
      expect(c[StatusGroup.active], 1);
      expect(c[StatusGroup.closed], 3);
      expect(c[StatusGroup.all], 6);
      expect(
        c[StatusGroup.open]! + c[StatusGroup.active]! + c[StatusGroup.closed]!,
        c[StatusGroup.all],
      );
    });
    test('empty list', () {
      final c = countByGroup(const []);
      expect(c[StatusGroup.all], 0);
      expect(c[StatusGroup.open], 0);
    });
  });
}
