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

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'email': email,
    'role': role.name,
  };

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
