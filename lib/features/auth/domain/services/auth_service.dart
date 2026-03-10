import '../models/driver_user.dart';

/// Pure domain auth service - ZERO framework imports
/// Business logic only, no infrastructure dependencies
class AuthService {
  /// Validate email format
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password requirements (12+ chars, 1 upper, 1 lower, 1 number)
  bool isValidPassword(String password) {
    return password.length >= 12;
  }

  /// Detailed password validation with specific error messages
  PasswordValidation validatePassword(String password) {
    if (password.length < 12) {
      return const PasswordValidation(
        valid: false,
        reason: 'Password must be at least 12 characters',
      );
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return const PasswordValidation(
        valid: false,
        reason: 'Password must contain at least one uppercase letter',
      );
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return const PasswordValidation(
        valid: false,
        reason: 'Password must contain at least one lowercase letter',
      );
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return const PasswordValidation(
        valid: false,
        reason: 'Password must contain at least one number',
      );
    }
    return const PasswordValidation(valid: true, reason: null);
  }

  /// Validate UK mobile phone number
  bool isValidUKPhone(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    // UK mobile: 07xxx or +447xxx
    final ukMobileRegex = RegExp(r'^(\+44|0)7\d{9}$');
    return ukMobileRegex.hasMatch(cleaned);
  }

  /// Normalize UK phone to +44 format
  String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.startsWith('0')) {
      return '+44${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Validate name (non-empty)
  bool isValidName(String name) {
    return name.trim().isNotEmpty;
  }

  /// Check if driver can access the app based on status
  bool canAccessApp(DriverUser user) {
    return user.status == DriverStatus.active ||
        user.status == DriverStatus.onboarding;
  }

  /// Determine onboarding step based on user status
  OnboardingStep getOnboardingStep(DriverUser user) {
    if (user.status == DriverStatus.pending) {
      return OnboardingStep.awaitingApproval;
    }
    if (user.status == DriverStatus.onboarding) {
      return OnboardingStep.profileSetup;
    }
    if (user.status == DriverStatus.suspended) {
      return OnboardingStep.suspended;
    }
    return OnboardingStep.complete;
  }

  /// Get user greeting based on time of day
  String getGreeting(DriverUser user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$greeting, ${user.firstName}';
  }
}

/// Onboarding step enum
enum OnboardingStep {
  awaitingApproval,
  profileSetup,
  documentUpload,
  vehicleSetup,
  complete,
  suspended,
}

/// Password validation result
class PasswordValidation {
  final bool valid;
  final String? reason;

  const PasswordValidation({
    required this.valid,
    this.reason,
  });
}
