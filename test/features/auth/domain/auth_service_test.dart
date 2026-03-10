import 'package:flutter_test/flutter_test.dart';
import 'package:relay_drivers/features/auth/domain/models/driver_user.dart';
import 'package:relay_drivers/features/auth/domain/services/auth_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
  });

  group('AuthService', () {
    group('isValidEmail', () {
      test('returns true for valid email', () {
        expect(authService.isValidEmail('test@example.com'), isTrue);
        expect(authService.isValidEmail('user.name@domain.co.uk'), isTrue);
      });

      test('returns false for invalid email', () {
        expect(authService.isValidEmail(''), isFalse);
        expect(authService.isValidEmail('invalid'), isFalse);
        expect(authService.isValidEmail('@domain.com'), isFalse);
        expect(authService.isValidEmail('user@'), isFalse);
      });
    });

    group('isValidPassword', () {
      test('returns true for password >= 12 chars', () {
        expect(authService.isValidPassword('123456789012'), isTrue);
        expect(authService.isValidPassword('PasswordStrong1'), isTrue);
      });

      test('returns false for password < 12 chars', () {
        expect(authService.isValidPassword(''), isFalse);
        expect(authService.isValidPassword('12345678'), isFalse);
        expect(authService.isValidPassword('12345678901'), isFalse);
      });
    });

    group('validatePassword', () {
      test('returns valid for strong password', () {
        final result = authService.validatePassword('Password1234');
        expect(result.valid, isTrue);
        expect(result.reason, isNull);
      });

      test('returns invalid for short password', () {
        final result = authService.validatePassword('Pass1');
        expect(result.valid, isFalse);
        expect(result.reason, 'Password must be at least 12 characters');
      });

      test('returns invalid for no uppercase', () {
        final result = authService.validatePassword('password1234');
        expect(result.valid, isFalse);
        expect(result.reason, 'Password must contain at least one uppercase letter');
      });

      test('returns invalid for no lowercase', () {
        final result = authService.validatePassword('PASSWORD1234');
        expect(result.valid, isFalse);
        expect(result.reason, 'Password must contain at least one lowercase letter');
      });

      test('returns invalid for no number', () {
        final result = authService.validatePassword('PasswordABCDE');
        expect(result.valid, isFalse);
        expect(result.reason, 'Password must contain at least one number');
      });
    });

    group('isValidUKPhone', () {
      test('returns true for valid UK mobile', () {
        expect(authService.isValidUKPhone('07700900000'), isTrue);
        expect(authService.isValidUKPhone('+447700900000'), isTrue);
        expect(authService.isValidUKPhone('07700 900 000'), isTrue);
      });

      test('returns false for invalid phone', () {
        expect(authService.isValidUKPhone(''), isFalse);
        expect(authService.isValidUKPhone('123456'), isFalse);
        expect(authService.isValidUKPhone('01onal12345'), isFalse);
      });
    });

    group('normalizePhone', () {
      test('converts 07 to +447', () {
        expect(authService.normalizePhone('07700900000'), '+447700900000');
      });

      test('keeps +44 format', () {
        expect(authService.normalizePhone('+447700900000'), '+447700900000');
      });

      test('removes spaces and dashes', () {
        expect(authService.normalizePhone('07700-900-000'), '+447700900000');
        expect(authService.normalizePhone('07700 900 000'), '+447700900000');
      });
    });

    group('isValidName', () {
      test('returns true for valid name', () {
        expect(authService.isValidName('John'), isTrue);
        expect(authService.isValidName('Jane Doe'), isTrue);
      });

      test('returns false for empty name', () {
        expect(authService.isValidName(''), isFalse);
        expect(authService.isValidName('   '), isFalse);
      });
    });

    group('canAccessApp', () {
      test('returns true for active driver', () {
        final user = _createDriver(status: DriverStatus.active);
        expect(authService.canAccessApp(user), isTrue);
      });

      test('returns true for onboarding driver', () {
        final user = _createDriver(status: DriverStatus.onboarding);
        expect(authService.canAccessApp(user), isTrue);
      });

      test('returns false for pending driver', () {
        final user = _createDriver(status: DriverStatus.pending);
        expect(authService.canAccessApp(user), isFalse);
      });

      test('returns false for suspended driver', () {
        final user = _createDriver(status: DriverStatus.suspended);
        expect(authService.canAccessApp(user), isFalse);
      });
    });

    group('getOnboardingStep', () {
      test('returns awaitingApproval for pending', () {
        final user = _createDriver(status: DriverStatus.pending);
        expect(
          authService.getOnboardingStep(user),
          OnboardingStep.awaitingApproval,
        );
      });

      test('returns profileSetup for onboarding', () {
        final user = _createDriver(status: DriverStatus.onboarding);
        expect(
          authService.getOnboardingStep(user),
          OnboardingStep.profileSetup,
        );
      });

      test('returns complete for active', () {
        final user = _createDriver(status: DriverStatus.active);
        expect(authService.getOnboardingStep(user), OnboardingStep.complete);
      });

      test('returns suspended for suspended', () {
        final user = _createDriver(status: DriverStatus.suspended);
        expect(authService.getOnboardingStep(user), OnboardingStep.suspended);
      });
    });
  });
}

DriverUser _createDriver({required DriverStatus status}) {
  return DriverUser(
    driverId: 'DRV-001',
    tenantId: 'TENANT#001',
    email: 'driver@example.com',
    firstName: 'John',
    lastName: 'Doe',
    status: status,
  );
}
