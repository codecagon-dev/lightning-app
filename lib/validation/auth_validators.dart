enum AuthValidationError { invalidEmail, invalidPassword }

class AuthValidationException implements Exception {
  const AuthValidationException(this.error);
  final AuthValidationError error;
}

abstract final class AuthValidators {
  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static AuthValidationError? email(String value) {
    final email = normalizeEmail(value);
    return email.runes.length <= 254 &&
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : AuthValidationError.invalidEmail;
  }

  static AuthValidationError? password(String value) {
    // Passwords deliberately retain leading and trailing whitespace.
    final length = value.runes.length;
    return length >= 12 && length <= 128
        ? null
        : AuthValidationError.invalidPassword;
  }
}
