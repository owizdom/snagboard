/// Form validators. Each returns null when the value is valid, otherwise the
/// message shown under the field.
library;

/// Email domains allowed to use the app.
const allowedEmailDomains = ['alustudent.com', 'alueducation.com'];

/// Accepts `name@alustudent.com` and `name@alueducation.com`, including
/// plus-addressing (`name+staff@alustudent.com`). Case-insensitive.
String? validateAluEmail(String? value) {
  final email = (value ?? '').trim().toLowerCase();
  if (email.isEmpty) return 'Enter your ALU email';
  const message = 'Use your ALU email (@alustudent.com or @alueducation.com)';
  final at = email.indexOf('@');
  // Exactly one "@", with something before it.
  if (at < 1 || at != email.lastIndexOf('@')) return message;
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  if (local.contains(RegExp(r'\s'))) return message;
  // The domain must be exactly an allowed one, nothing before or after.
  if (!allowedEmailDomains.contains(domain)) return message;
  return null;
}

/// At least 8 characters with at least one letter and one digit.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter a password';
  if (password.length < 8) return 'Use at least 8 characters';
  if (!password.contains(RegExp(r'[A-Za-z]'))) {
    return 'Add at least one letter';
  }
  if (!password.contains(RegExp(r'[0-9]'))) return 'Add at least one digit';
  return null;
}

String? validateConfirm(String? value, String password) {
  if (value == null || value.isEmpty) return 'Repeat your password';
  if (value != password) return 'Passwords do not match';
  return null;
}

/// Checks the trimmed length of [value] against [min] and [max].
String? _lengthBetween(String? value, int min, int max, String what) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Enter $what';
  if (text.length < min) {
    return '${_cap(what)} must be at least $min characters';
  }
  if (text.length > max) {
    return '${_cap(what)} must be at most $max characters';
  }
  return null;
}

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

/// 2 to 60 characters after trimming.
String? validateName(String? value) =>
    _lengthBetween(value, 2, 60, 'your name');

/// 5 to 80 characters after trimming.
String? validateTitle(String? value) => _lengthBetween(value, 5, 80, 'a title');

/// 15 to 1000 characters after trimming.
String? validateDescription(String? value) =>
    _lengthBetween(value, 15, 1000, 'a description');

/// 3 to 280 characters after trimming.
String? validateNote(String? value) => _lengthBetween(value, 3, 280, 'a note');
