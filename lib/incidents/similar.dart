import 'incident.dart';

/// Open snags (submitted or acknowledged) with the same category and the
/// same location, newest first. Used to offer "affects me too" instead of
/// a duplicate report.
List<Incident> findSimilar(
  List<Incident> all,
  IncidentCategory category,
  String location,
) =>
    all
        .where(
          (i) => i.isOpen && i.category == category && i.location == location,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
