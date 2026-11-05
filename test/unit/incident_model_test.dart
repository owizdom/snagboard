import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/incidents/incident.dart';

import '../fakes/fakes.dart';

void expectSame(Incident a, Incident b) {
  expect(b.id, a.id);
  expect(b.title, a.title);
  expect(b.description, a.description);
  expect(b.category, a.category);
  expect(b.location, a.location);
  expect(b.spot, a.spot);
  expect(b.urgency, a.urgency);
  expect(b.photoUrl, a.photoUrl);
  expect(b.photoPath, a.photoPath);
  expect(b.status, a.status);
  expect(b.reporterId, a.reporterId);
  expect(b.reporterName, a.reporterName);
  expect(b.anonymous, a.anonymous);
  expect(b.affectedBy, a.affectedBy);
  expect(b.createdAt, a.createdAt);
  expect(b.updatedAt, a.updatedAt);
  expect(b.history.length, a.history.length);
  for (var i = 0; i < a.history.length; i++) {
    expect(b.history[i].status, a.history[i].status);
    expect(b.history[i].note, a.history[i].note);
    expect(b.history[i].byName, a.history[i].byName);
    expect(b.history[i].at, a.history[i].at);
  }
}

void main() {
  test('round trip keeps every field', () {
    final i = makeIncident(
      id: 'abcd1234',
      category: IncidentCategory.electricity,
      urgency: Urgency.urgent,
      status: IncidentStatus.inProgress,
      affectedBy: ['u1', 'u2'],
      photoUrl: 'https://example.test/p.jpg',
      photoPath: 'incident_photos/stu1/1.jpg',
      history: [
        StatusChange(
          status: IncidentStatus.submitted,
          note: 'Filed',
          byName: 'Amani',
          at: DateTime(2026, 11, 1, 9),
        ),
        StatusChange(
          status: IncidentStatus.inProgress,
          note: 'On it',
          byName: 'Desk',
          at: DateTime(2026, 11, 2, 10, 30),
        ),
      ],
    );
    expectSame(i, Incident.fromMap(i.id, i.toMap()));
  });

  test('null photo, null spot and null reporterName survive', () {
    final i = makeIncident(spot: null, anonymous: true);
    final back = Incident.fromMap(i.id, i.toMap());
    expect(back.photoUrl, isNull);
    expect(back.photoPath, isNull);
    expect(back.spot, isNull);
    expect(back.reporterName, isNull);
    expect(back.anonymous, isTrue);
  });

  test('toMap writes the wire value for status and names for enums', () {
    final m = makeIncident(status: IncidentStatus.inProgress).toMap();
    expect(m['status'], 'in_progress');
    expect(m['category'], 'water');
    expect(m['urgency'], 'normal');
    final h = (m['history'] as List).first as Map;
    expect(h['status'], 'submitted');
  });

  test('toMap writes DateTime for dates and exactly the contract keys', () {
    final m = makeIncident().toMap();
    expect(m['createdAt'], isA<DateTime>());
    expect(m['updatedAt'], isA<DateTime>());
    expect(m.keys.toSet(), {
      'title',
      'description',
      'category',
      'location',
      'spot',
      'urgency',
      'status',
      'photoUrl',
      'photoPath',
      'reporterId',
      'reporterName',
      'anonymous',
      'affectedBy',
      'history',
      'createdAt',
      'updatedAt',
    });
  });

  test('fromMap accepts DateTime values for every date', () {
    final created = DateTime(2026, 10, 30, 8);
    final updated = DateTime(2026, 10, 31, 9);
    final at = DateTime(2026, 10, 30, 8, 5);
    final i = Incident.fromMap('xyz98765', {
      'title': 'Broken lift',
      'description': 'The lift is stuck between floors.',
      'category': 'facilities',
      'location': 'Main Building',
      'spot': null,
      'urgency': 'urgent',
      'status': 'acknowledged',
      'photoUrl': null,
      'photoPath': null,
      'reporterId': 'stu1',
      'reporterName': 'Amani',
      'anonymous': false,
      'affectedBy': ['stu2'],
      'history': [
        {'status': 'submitted', 'note': 'Filed', 'byName': 'Amani', 'at': at},
      ],
      'createdAt': created,
      'updatedAt': updated,
    });
    expect(i.createdAt, created);
    expect(i.updatedAt, updated);
    expect(i.history.single.at, at);
    expect(i.status, IncidentStatus.acknowledged);
    expect(i.category, IncidentCategory.facilities);
    expect(i.urgency, Urgency.urgent);
    expect(i.affectedBy, ['stu2']);
  });

  test('unknown category and status strings fall back without throwing', () {
    final m = makeIncident().toMap()
      ..['category'] = 'dragons'
      ..['status'] = 'exploded';
    final i = Incident.fromMap('abcd1234', m);
    expect(i.category, IncidentCategory.other);
    expect(i.status, IncidentStatus.submitted);
  });

  test('ticketCode is SNG- plus first four chars upper case', () {
    expect(makeIncident(id: 'abcd1234').ticketCode, 'SNG-ABCD');
    expect(makeIncident(id: 'x9y8z7').ticketCode, 'SNG-X9Y8');
  });

  test('wire values and codes', () {
    expect(IncidentStatus.inProgress.wire, 'in_progress');
    expect(IncidentCategory.water.code, 'WTR');
    expect(IncidentStatus.fromWire('in_progress'), IncidentStatus.inProgress);
  });
}
