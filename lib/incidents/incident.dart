/// A snag: one problem on campus that needs fixing, as stored in
/// Firestore under `incidents/{id}`.
library;

enum IncidentCategory {
  facilities('FAC', 'Facilities', 'Doors, windows, lifts, broken fittings'),
  water('WTR', 'Water', 'No supply, leaks, low pressure'),
  electricity('PWR', 'Electricity', 'Outages, dead sockets, faulty lights'),
  furniture('FRN', 'Furniture', 'Broken chairs, desks, beds'),
  sanitation('SAN', 'Sanitation', 'Toilets, bins, cleaning, pests'),
  safety('SAF', 'Safety', 'Hazards, security, anything that could hurt someone'),
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
  static IncidentStatus fromWire(Object? value) => IncidentStatus.values
      .firstWhere((s) => s.wire == value, orElse: () => IncidentStatus.submitted);
}

enum Urgency {
  low('Low'),
  normal('Normal'),
  urgent('Urgent');

  const Urgency(this.label);
  final String label;

  static Urgency fromWire(Object? value) =>
      Urgency.values.firstWhere((u) => u.name == value, orElse: () => Urgency.normal);
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

  Map<String, dynamic> toMap() => throw UnimplementedError();

  factory StatusChange.fromMap(Map<String, dynamic> map) =>
      throw UnimplementedError();
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
  String get ticketCode => throw UnimplementedError();

  bool get isOpen =>
      status == IncidentStatus.submitted || status == IncidentStatus.acknowledged;

  Incident copyWith({
    IncidentStatus? status,
    List<String>? affectedBy,
    List<StatusChange>? history,
    DateTime? updatedAt,
    String? title,
    String? description,
  }) =>
      Incident(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category,
        location: location,
        spot: spot,
        urgency: urgency,
        photoUrl: photoUrl,
        photoPath: photoPath,
        status: status ?? this.status,
        reporterId: reporterId,
        reporterName: reporterName,
        anonymous: anonymous,
        affectedBy: affectedBy ?? this.affectedBy,
        history: history ?? this.history,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Firestore map. `createdAt` and `updatedAt` are written as
  /// [DateTime]s here; the repository swaps in server timestamps.
  Map<String, dynamic> toMap() => throw UnimplementedError();

  /// Accepts Firestore `Timestamp`s or [DateTime]s for dates. Unknown
  /// enum strings fall back instead of throwing.
  factory Incident.fromMap(String id, Map<String, dynamic> map) =>
      throw UnimplementedError();
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
  }) =>
      IncidentDraft(
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
