/// Form validators. Each returns null when the value is valid, otherwise the
/// message shown under the field.
library;

/// Email domains allowed to use the app.
const allowedEmailDomains = ['alustudent.com', 'alueducation.com'];

/// Accepts `name@alustudent.com` and `name@alueducation.com`, including
/// plus-addressing (`name+staff@alustudent.com`). Case-insensitive.
String? validateAluEmail(String? value) => throw UnimplementedError();

/// At least 8 characters with at least one letter and one digit.
String? validatePassword(String? value) => throw UnimplementedError();

String? validateConfirm(String? value, String password) =>
    throw UnimplementedError();

/// 2 to 60 characters after trimming.
String? validateName(String? value) => throw UnimplementedError();

/// 5 to 80 characters after trimming.
String? validateTitle(String? value) => throw UnimplementedError();

/// 15 to 1000 characters after trimming.
String? validateDescription(String? value) => throw UnimplementedError();

/// 3 to 280 characters after trimming.
String? validateNote(String? value) => throw UnimplementedError();
