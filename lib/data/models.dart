import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

enum UserRole {
  student,
  staff;

  static UserRole fromWire(Object? value) =>
      value == 'staff' ? UserRole.staff : UserRole.student;
}

/// A signed-in person's profile, stored at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.programme,
    this.photoUrl,
    this.photoPath,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  /// Degree for students, department for staff. Null until set.
  final String? programme;
  final String? photoUrl;
  final String? photoPath;

  /// Up to two initials for the avatar placeholder.
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    email: (map['email'] ?? '') as String,
    displayName: (map['displayName'] ?? '') as String,
    role: UserRole.fromWire(map['role']),
    programme: map['programme'] as String?,
    photoUrl: map['photoUrl'] as String?,
    photoPath: map['photoPath'] as String?,
  );
}

/// What Firebase Auth knows about the current sign-in.
class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final bool emailVerified;
}

/// A snag: one problem on campus that needs fixing, as stored in
/// Firestore under `incidents/{id}`.

/// Reads a Firestore [Timestamp] or [DateTime]; null (a pending server
/// timestamp) becomes now.
DateTime _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

enum IncidentCategory {
  facilities('FAC', 'Facilities', 'Doors, windows, lifts, broken fittings'),
  water('WTR', 'Water', 'No supply, leaks, low pressure'),
  electricity('PWR', 'Electricity', 'Outages, dead sockets, faulty lights'),
  furniture('FRN', 'Furniture', 'Broken chairs, desks, beds'),
  sanitation('SAN', 'Sanitation', 'Toilets, bins, cleaning, pests'),
  safety(
    'SAF',
    'Safety',
    'Hazards, security, anything that could hurt someone',
  ),
  internet('NET', 'Internet', 'Wi-Fi down or too slow to work'),
  other('OTH', 'Other', 'Anything that fits nowhere else');

  const IncidentCategory(this.code, this.label, this.hint);

  /// Three-letter code printed on tickets, e.g. `WTR`.
  final String code;
  final String label;
  final String hint;

  /// Unknown or missing values fall back to [other] instead of crashing.
  static IncidentCategory fromWire(Object? value) => IncidentCategory.values
      .firstWhere((c) => c.name == value, orElse: () => IncidentCategory.other);
}

enum IncidentStatus {
  submitted('submitted', 'Submitted'),
  acknowledged('acknowledged', 'Acknowledged'),
  inProgress('in_progress', 'In progress'),
  resolved('resolved', 'Resolved'),
  declined('declined', 'Declined');

  const IncidentStatus(this.wire, this.label);

  /// The string stored in Firestore.
  final String wire;
  final String label;

  /// Unknown or missing values fall back to [submitted].
  static IncidentStatus fromWire(Object? value) =>
      IncidentStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => IncidentStatus.submitted,
      );
}

enum Urgency {
  low('Low'),
  normal('Normal'),
  urgent('Urgent');

  const Urgency(this.label);
  final String label;

  static Urgency fromWire(Object? value) => Urgency.values.firstWhere(
    (u) => u.name == value,
    orElse: () => Urgency.normal,
  );
}

/// Board filter groups. open = submitted + acknowledged, active = in
/// progress, closed = resolved + declined.
enum StatusGroup { all, open, active, closed }

/// One stop on a snag's status track.
class StatusChange {
  const StatusChange({
    required this.status,
    required this.note,
    required this.byName,
    required this.at,
  });

  final IncidentStatus status;
  final String note;
  final String byName;
  final DateTime at;

  Map<String, dynamic> toMap() => {
    'status': status.wire,
    'note': note,
    'byName': byName,
    'at': at,
  };

  factory StatusChange.fromMap(Map<String, dynamic> map) => StatusChange(
    status: IncidentStatus.fromWire(map['status']),
    note: (map['note'] ?? '') as String,
    byName: (map['byName'] ?? '') as String,
    at: _readDate(map['at']),
  );
}

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.spot,
    required this.urgency,
    this.photoUrl,
    this.photoPath,
    required this.status,
    required this.reporterId,
    this.reporterName,
    required this.anonymous,
    this.affectedBy = const [],
    this.history = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final String? spot;
  final Urgency urgency;
  final String? photoUrl;
  final String? photoPath;
  final IncidentStatus status;
  final String reporterId;

  /// Null when the reporter hid their name from other students.
  final String? reporterName;
  final bool anonymous;
  final List<String> affectedBy;
  final List<StatusChange> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 'SNG-' plus the first four characters of the id, upper case.
  String get ticketCode =>
      'SNG-${(id.length < 4 ? id : id.substring(0, 4)).toUpperCase()}';

  bool get isOpen =>
      status == IncidentStatus.submitted ||
      status == IncidentStatus.acknowledged;

  /// Accepts Firestore `Timestamp`s or [DateTime]s for dates. Unknown
  /// enum strings fall back instead of throwing.
  factory Incident.fromMap(String id, Map<String, dynamic> map) => Incident(
    id: id,
    title: (map['title'] ?? '') as String,
    description: (map['description'] ?? '') as String,
    category: IncidentCategory.fromWire(map['category']),
    location: (map['location'] ?? '') as String,
    spot: map['spot'] as String?,
    urgency: Urgency.fromWire(map['urgency']),
    photoUrl: map['photoUrl'] as String?,
    photoPath: map['photoPath'] as String?,
    status: IncidentStatus.fromWire(map['status']),
    reporterId: (map['reporterId'] ?? '') as String,
    reporterName: map['reporterName'] as String?,
    anonymous: (map['anonymous'] ?? false) as bool,
    affectedBy: [
      for (final u in (map['affectedBy'] as List? ?? const [])) u as String,
    ],
    history: [
      for (final h in (map['history'] as List? ?? const []))
        StatusChange.fromMap(Map<String, dynamic>.from(h as Map)),
    ],
    createdAt: _readDate(map['createdAt']),
    updatedAt: _readDate(map['updatedAt']),
  );
}

/// What the filing form collects before anything is saved.
class IncidentDraft {
  const IncidentDraft({
    this.title = '',
    this.description = '',
    this.category,
    this.location,
    this.spot,
    this.urgency = Urgency.normal,
    this.anonymous = false,
    this.photoPath,
  });

  final String title;
  final String description;
  final IncidentCategory? category;
  final String? location;
  final String? spot;
  final Urgency urgency;
  final bool anonymous;

  /// Local file path of a picked photo, not yet uploaded.
  final String? photoPath;

  IncidentDraft copyWith({
    String? title,
    String? description,
    IncidentCategory? category,
    String? location,
    String? spot,
    Urgency? urgency,
    bool? anonymous,
    String? photoPath,
    bool clearPhoto = false,
  }) => IncidentDraft(
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    location: location ?? this.location,
    spot: spot ?? this.spot,
    urgency: urgency ?? this.urgency,
    anonymous: anonymous ?? this.anonymous,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
  );

  factory IncidentDraft.fromIncident(Incident i) => IncidentDraft(
    title: i.title,
    description: i.description,
    category: i.category,
    location: i.location,
    spot: i.spot,
    urgency: i.urgency,
    anonymous: i.anonymous,
  );
}

/// The statuses staff may move a snag to from [from].
///
/// submitted    -> acknowledged | inProgress | declined
/// acknowledged -> inProgress | declined
/// inProgress   -> resolved
/// resolved     -> inProgress   (reopen when the fix did not hold)
/// declined     -> acknowledged (reopen)
List<IncidentStatus> nextStatuses(IncidentStatus from) => switch (from) {
  IncidentStatus.submitted => const [
    IncidentStatus.acknowledged,
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  ],
  IncidentStatus.acknowledged => const [
    IncidentStatus.inProgress,
    IncidentStatus.declined,
  ],
  IncidentStatus.inProgress => const [IncidentStatus.resolved],
  IncidentStatus.resolved => const [IncidentStatus.inProgress],
  IncidentStatus.declined => const [IncidentStatus.acknowledged],
};

bool canTransition(IncidentStatus from, IncidentStatus to) =>
    nextStatuses(from).contains(to);

/// Places a snag can be filed against. Kept in one list so staff can
/// adjust it without touching any screen.
const campusLocations = [
  'Main Building',
  'Library',
  'Innovation Lab',
  'Lecture Hall A',
  'Lecture Hall B',
  'Cafeteria',
  'Student Residence A',
  'Student Residence B',
  'Sports Ground',
  'Admin Block',
  'Parking',
  'Outdoor Grounds',
];

/// Degrees a student can pick on their profile.
const studentProgrammes = [
  'BSc Software Engineering',
  'BSc Entrepreneurial Leadership',
  'BSc International Business & Trade',
  'Other',
];

/// Departments a staff member can pick on their profile.
const staffDepartments = [
  'Facilities',
  'IT Support',
  'Campus Security',
  'Student Life',
  'Residence Life',
  'Administration',
  'Other',
];
