import 'incident.dart';

/// Open snags (submitted or acknowledged) with the same category and the
/// same location, newest first. Used to offer "affects me too" instead of
/// a duplicate report.
List<Incident> findSimilar(
  List<Incident> all,
  IncidentCategory category,
  String location,
) =>
    throw UnimplementedError();
