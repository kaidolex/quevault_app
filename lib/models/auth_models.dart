/// Authentication result model
class AuthResult {
  final bool success;
  final String? message;
  final AuthError? error;

  const AuthResult({required this.success, this.message, this.error});

  factory AuthResult.success({String? message}) {
    return AuthResult(success: true, message: message);
  }

  factory AuthResult.failure({required String message, AuthError? error}) {
    return AuthResult(success: false, message: message, error: error);
  }
}

/// Authentication error types
enum AuthError { invalidPassword, passwordMismatch, weakPassword, storageError, unknown }

/// Password strength levels
enum PasswordStrength { none, weak, medium, strong }

/// Master password setup request model
class MasterPasswordSetupRequest {
  final String password;
  final String confirmPassword;

  const MasterPasswordSetupRequest({required this.password, required this.confirmPassword});

  /// Validates the password setup request
  AuthResult validate() {
    if (password.isEmpty) {
      return AuthResult.failure(message: 'Password cannot be empty', error: AuthError.invalidPassword);
    }

    if (password.length < 8) {
      return AuthResult.failure(message: 'Password must be at least 8 characters long', error: AuthError.weakPassword);
    }

    if (password != confirmPassword) {
      return AuthResult.failure(message: 'Passwords do not match', error: AuthError.passwordMismatch);
    }

    final strength = getPasswordStrength(password);
    if (strength == PasswordStrength.weak) {
      return AuthResult.failure(message: 'Please choose a stronger password', error: AuthError.weakPassword);
    }

    return AuthResult.success(message: 'Password is valid');
  }

  /// Gets the strength of the password
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 8) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

/// Login request model
class LoginRequest {
  final String password;

  const LoginRequest({required this.password});

  AuthResult validate() {
    if (password.isEmpty) {
      return AuthResult.failure(message: 'Password cannot be empty', error: AuthError.invalidPassword);
    }
    return AuthResult.success();
  }
}

/// Change password request model
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  const ChangePasswordRequest({required this.currentPassword, required this.newPassword, required this.confirmNewPassword});

  AuthResult validate() {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return AuthResult.failure(message: 'Passwords cannot be empty', error: AuthError.invalidPassword);
    }

    if (newPassword.length < 8) {
      return AuthResult.failure(message: 'New password must be at least 8 characters long', error: AuthError.weakPassword);
    }

    if (newPassword != confirmNewPassword) {
      return AuthResult.failure(message: 'New passwords do not match', error: AuthError.passwordMismatch);
    }

    return AuthResult.success();
  }
}
