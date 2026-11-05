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
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

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
