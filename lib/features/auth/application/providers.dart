import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/auth_state.dart';
import '../domain/models/driver_user.dart';
import '../domain/models/invite_models.dart';
import '../domain/models/login_request.dart';
import '../domain/models/otp_models.dart';
import '../domain/services/auth_service.dart';
import '../infrastructure/auth_repository.dart';
import '../infrastructure/biometric_service.dart';

/// DioClient provider - singleton instance
/// Note: Auth invalidation callback set up lazily to avoid circular dependency
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient: dioClient);
});

/// Auth service provider (pure domain logic)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final AuthService _authService;

  AuthNotifier({
    required AuthRepository repository,
    required AuthService authService,
  })  : _repository = repository,
        _authService = authService,
        super(const AuthInitial());

  /// Check existing session on app start
  Future<void> checkSession() async {
    state = const AuthLoading();

    try {
      final hasToken = await _repository.hasValidToken();
      if (!hasToken) {
        state = const AuthUnauthenticated();
        return;
      }

      final user = await _repository.getSession();

      if (_authService.canAccessApp(user)) {
        state = AuthAuthenticated(user: user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Register new driver
  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    // Validate all fields
    if (!_authService.isValidEmail(email)) {
      state = const AuthError(message: 'Invalid email format');
      return;
    }
    if (!_authService.isValidName(firstName)) {
      state = const AuthError(message: 'First name is required');
      return;
    }
    if (!_authService.isValidName(lastName)) {
      state = const AuthError(message: 'Last name is required');
      return;
    }
    if (!_authService.isValidUKPhone(phone)) {
      state = const AuthError(message: 'Valid UK mobile phone number required');
      return;
    }
    final pwdValidation = _authService.validatePassword(password);
    if (!pwdValidation.valid) {
      state = AuthError(message: pwdValidation.reason ?? 'Invalid password');
      return;
    }

    state = const AuthLoading();

    try {
      final request = RegisterRequest(
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: _authService.normalizePhone(phone),
        password: password,
      );
      final response = await _repository.register(request);
      await _repository.saveTokens(response);

      if (_authService.canAccessApp(response.user)) {
        state = AuthAuthenticated(user: response.user);
      } else {
        state = const AuthError(message: 'Account pending approval');
      }
    } catch (e) {
      state = AuthError(message: _parseError(e));
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    if (!_authService.isValidEmail(email)) {
      state = const AuthError(message: 'Invalid email format');
      return;
    }

    if (!_authService.isValidPassword(password)) {
      state = const AuthError(message: 'Password must be at least 12 characters');
      return;
    }

    state = const AuthLoading();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _repository.login(request);
      await _repository.saveTokens(response);

      if (_authService.canAccessApp(response.user)) {
        state = AuthAuthenticated(user: response.user);
      } else {
        state = const AuthError(message: 'Account pending approval');
      }
    } catch (e) {
      state = AuthError(message: _parseError(e));
    }
  }

  /// Request magic link
  Future<bool> requestMagicLink(String email) async {
    if (!_authService.isValidEmail(email)) {
      state = const AuthError(message: 'Invalid email format');
      return false;
    }

    state = const AuthLoading();

    try {
      final request = MagicLinkRequest(email: email);
      await _repository.requestMagicLink(request);
      state = const AuthUnauthenticated();
      return true;
    } catch (e) {
      state = AuthError(message: _parseError(e));
      return false;
    }
  }

  /// Verify magic link token
  Future<void> verifyMagicLink(String token) async {
    state = const AuthLoading();

    try {
      final request = VerifyMagicLinkRequest(token: token);
      final response = await _repository.verifyMagicLink(request);
      await _repository.saveTokens(response);

      if (_authService.canAccessApp(response.user)) {
        state = AuthAuthenticated(user: response.user);
      } else {
        state = const AuthError(message: 'Account pending approval');
      }
    } catch (e) {
      state = AuthError(message: _parseError(e));
    }
  }

  /// Logout
  Future<void> logout() async {
    await _repository.clearTokens();
    state = const AuthUnauthenticated();
  }

  /// Set authenticated state directly (used by invite flow)
  void setAuthenticated(DriverUser user) {
    state = AuthAuthenticated(user: user);
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final dioClient = ref.watch(dioClientProvider);

  final notifier = AuthNotifier(repository: repository, authService: authService);

  // Wire up auth invalidation callback now that we have both providers
  dioClient.setAuthInvalidatedCallback(() {
    notifier.logout();
  });

  return notifier;
});

/// Current user provider (derived from auth state)
final currentUserProvider = Provider<DriverUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
});

// ============ Phone OTP Authentication ============

/// Phone auth state notifier
class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  final AuthRepository _repository;
  final AuthService _authService;
  final DioClient _dioClient;

  PhoneAuthNotifier({
    required AuthRepository repository,
    required AuthService authService,
    required DioClient dioClient,
  })  : _repository = repository,
        _authService = authService,
        _dioClient = dioClient,
        super(const PhoneAuthInitial());

  /// Reset to initial state
  void reset() {
    state = const PhoneAuthInitial();
  }

  /// Request OTP for phone number
  Future<void> requestOtp(String phone) async {
    // Validate phone format
    if (!_authService.isValidUKPhone(phone)) {
      state = PhoneAuthError(
        message: 'Please enter a valid UK mobile number',
        phone: phone,
      );
      return;
    }

    final normalizedPhone = _authService.normalizePhone(phone);
    state = PhoneAuthChecking(phone: normalizedPhone);

    try {
      // Check if identity exists for welcome message
      final identityCheck = await _repository.checkIdentity(phone: normalizedPhone);

      // Request OTP
      await _repository.requestOtp(normalizedPhone);

      state = PhoneAuthOtpSent(
        phone: normalizedPhone,
        displayName: identityCheck.displayName,
        isExistingUser: identityCheck.exists,
        sentAt: DateTime.now(),
      );
    } catch (e) {
      state = PhoneAuthError(
        message: _parseError(e),
        phone: normalizedPhone,
      );
    }
  }

  /// Resend OTP (same phone)
  Future<void> resendOtp() async {
    final currentState = state;
    if (currentState is! PhoneAuthOtpSent) return;

    state = PhoneAuthChecking(phone: currentState.phone);

    try {
      await _repository.requestOtp(currentState.phone);

      state = PhoneAuthOtpSent(
        phone: currentState.phone,
        displayName: currentState.displayName,
        isExistingUser: currentState.isExistingUser,
        sentAt: DateTime.now(),
      );
    } catch (e) {
      state = PhoneAuthError(
        message: _parseError(e),
        phone: currentState.phone,
      );
    }
  }

  /// Verify OTP code
  Future<void> verifyOtp(String otp) async {
    final currentState = state;
    String phone;

    if (currentState is PhoneAuthOtpSent) {
      phone = currentState.phone;
    } else if (currentState is PhoneAuthError) {
      phone = currentState.phone;
    } else {
      return;
    }

    // Basic validation
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      state = PhoneAuthError(
        message: 'Please enter a valid 6-digit code',
        phone: phone,
      );
      return;
    }

    state = PhoneAuthVerifying(phone: phone);

    try {
      final response = await _repository.verifyOtp(phone, otp);

      // If we got a token, save it
      if (response.token != null) {
        await _dioClient.saveTokens(
          accessToken: response.token!,
          refreshToken: null,
        );
      }

      state = PhoneAuthSuccess(
        driver: response.driver,
        isNewDriver: response.isNewDriver,
      );
    } catch (e) {
      state = PhoneAuthError(
        message: _parseError(e),
        phone: phone,
      );
    }
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString();

    // Parse DioException response
    if (errorStr.contains('Too many')) {
      return 'Too many attempts. Please try again later.';
    }
    if (errorStr.contains('expired')) {
      return 'Code expired. Please request a new one.';
    }
    if (errorStr.contains('Invalid') || errorStr.contains('incorrect')) {
      return 'Invalid code. Please try again.';
    }
    if (errorStr.contains('rate') || errorStr.contains('429')) {
      return 'Too many requests. Please wait a moment.';
    }

    return 'An error occurred. Please try again.';
  }
}

/// Phone auth state provider
final phoneAuthStateProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final dioClient = ref.watch(dioClientProvider);

  return PhoneAuthNotifier(
    repository: repository,
    authService: authService,
    dioClient: dioClient,
  );
});

// ============ Biometric Authentication ============

/// Biometric service provider - singleton instance
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Biometric availability state
class BiometricAvailability {
  final bool isSupported;
  final bool isEnrolled;
  final bool isEnabled;
  final String biometricTypeName;

  const BiometricAvailability({
    required this.isSupported,
    required this.isEnrolled,
    required this.isEnabled,
    required this.biometricTypeName,
  });

  bool get canUseBiometric => isSupported && isEnrolled && isEnabled;
}

/// Biometric availability provider
final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>((ref) async {
  final biometricService = ref.watch(biometricServiceProvider);

  final isSupported = await biometricService.isDeviceSupported();
  final isEnrolled = await biometricService.canCheckBiometrics();
  final isEnabled = await biometricService.isBiometricEnabled();
  final types = await biometricService.getAvailableBiometrics();
  final typeName = biometricService.getBiometricTypeName(types);

  return BiometricAvailability(
    isSupported: isSupported,
    isEnrolled: isEnrolled,
    isEnabled: isEnabled,
    biometricTypeName: typeName,
  );
});

/// Biometric state notifier for authentication flow
class BiometricAuthNotifier extends StateNotifier<BiometricAuthState> {
  final BiometricService _biometricService;
  final DioClient _dioClient;

  BiometricAuthNotifier({
    required BiometricService biometricService,
    required DioClient dioClient,
  })  : _biometricService = biometricService,
        _dioClient = dioClient,
        super(const BiometricAuthInitial());

  /// Check if biometric unlock is needed
  Future<void> checkBiometricRequired() async {
    state = const BiometricAuthChecking();

    try {
      // Check if biometric is enabled
      final isEnabled = await _biometricService.isBiometricEnabled();
      if (!isEnabled) {
        state = const BiometricAuthNotRequired();
        return;
      }

      // Check if we have a stored session token
      final token = await _biometricService.getSessionToken();
      if (token == null) {
        state = const BiometricAuthNotRequired();
        return;
      }

      // Check if biometric is required today (24h rule)
      final requiresAuth = await _biometricService.requiresBiometricToday();
      if (!requiresAuth) {
        // Auto-restore session without biometric prompt
        await _dioClient.saveTokens(accessToken: token, refreshToken: null);
        state = const BiometricAuthSuccess();
        return;
      }

      // Biometric authentication required
      state = const BiometricAuthRequired();
    } catch (e) {
      state = BiometricAuthError(message: e.toString());
    }
  }

  /// Authenticate with biometrics
  Future<void> authenticate() async {
    state = const BiometricAuthAuthenticating();

    try {
      final result = await _biometricService.authenticate();

      if (result == BiometricResult.success) {
        // Restore session token
        final token = await _biometricService.getSessionToken();
        if (token != null) {
          await _dioClient.saveTokens(accessToken: token, refreshToken: null);
          state = const BiometricAuthSuccess();
        } else {
          state = const BiometricAuthError(message: 'Session expired. Please login again.');
        }
      } else {
        state = BiometricAuthFailed(
          message: result.message,
          canRetry: result.isRecoverable,
        );
      }
    } catch (e) {
      state = BiometricAuthError(message: e.toString());
    }
  }

  /// Enable biometric and store current session
  Future<void> enableBiometric(String token) async {
    await _biometricService.enableBiometric();
    await _biometricService.storeSessionToken(token);
  }

  /// Disable biometric
  Future<void> disableBiometric() async {
    await _biometricService.disableBiometric();
  }

  /// Skip biometric (use regular login)
  void skipBiometric() {
    state = const BiometricAuthSkipped();
  }
}

/// Biometric auth state
sealed class BiometricAuthState {
  const BiometricAuthState();
}

class BiometricAuthInitial extends BiometricAuthState {
  const BiometricAuthInitial();
}

class BiometricAuthChecking extends BiometricAuthState {
  const BiometricAuthChecking();
}

class BiometricAuthNotRequired extends BiometricAuthState {
  const BiometricAuthNotRequired();
}

class BiometricAuthRequired extends BiometricAuthState {
  const BiometricAuthRequired();
}

class BiometricAuthAuthenticating extends BiometricAuthState {
  const BiometricAuthAuthenticating();
}

class BiometricAuthSuccess extends BiometricAuthState {
  const BiometricAuthSuccess();
}

class BiometricAuthFailed extends BiometricAuthState {
  final String message;
  final bool canRetry;

  const BiometricAuthFailed({required this.message, required this.canRetry});
}

class BiometricAuthSkipped extends BiometricAuthState {
  const BiometricAuthSkipped();
}

class BiometricAuthError extends BiometricAuthState {
  final String message;

  const BiometricAuthError({required this.message});
}

/// Biometric auth state provider
final biometricAuthStateProvider =
    StateNotifierProvider<BiometricAuthNotifier, BiometricAuthState>((ref) {
  final biometricService = ref.watch(biometricServiceProvider);
  final dioClient = ref.watch(dioClientProvider);

  return BiometricAuthNotifier(
    biometricService: biometricService,
    dioClient: dioClient,
  );
});

// ============ Invite Authentication ============

/// Invite auth state notifier for invite-based driver onboarding
class InviteAuthNotifier extends StateNotifier<InviteAuthState> {
  final AuthRepository _repository;
  final AuthService _authService;
  final DioClient _dioClient;

  InviteAuthNotifier({
    required AuthRepository repository,
    required AuthService authService,
    required DioClient dioClient,
  })  : _repository = repository,
        _authService = authService,
        _dioClient = dioClient,
        super(const InviteAuthInitial());

  /// Reset to initial state
  void reset() {
    state = const InviteAuthInitial();
  }

  /// Verify invite code and get driver info
  Future<void> verifyInvite(String code) async {
    final trimmedCode = code.trim().toUpperCase();
    print('[InviteAuth] verifyInvite called with code: $trimmedCode');

    // Only check for empty - let the API validate the format
    if (trimmedCode.isEmpty) {
      state = const InviteAuthError(
        message: 'Please enter an invite code',
        isExpired: false,
        isUsed: false,
      );
      return;
    }

    state = InviteAuthVerifying(code: trimmedCode);

    try {
      print('[InviteAuth] Calling repository.verifyInvite...');
      final response = await _repository.verifyInvite(trimmedCode);
      print('[InviteAuth] Response received: firstName=${response.firstName}, lastName=${response.lastName}');

      state = InviteAuthVerified(
        code: trimmedCode,
        firstName: response.firstName,
        lastName: response.lastName,
        maskedPhone: response.maskedPhone,
        tenantId: response.tenantId,
      );
    } catch (e, stackTrace) {
      print('[InviteAuth] ERROR: $e');
      print('[InviteAuth] Stack: $stackTrace');
      final error = _parseInviteError(e);
      state = InviteAuthError(
        message: error.message,
        isExpired: error.isExpired,
        isUsed: error.isUsed,
      );
    }
  }

  /// Request OTP for invite claim
  Future<void> requestOtp(String phone) async {
    final currentState = state;
    if (currentState is! InviteAuthVerified) return;

    // Validate phone format
    if (!_authService.isValidUKPhone(phone)) {
      state = const InviteAuthError(
        message: 'Please enter a valid UK mobile number',
        isExpired: false,
        isUsed: false,
      );
      return;
    }

    final normalizedPhone = _authService.normalizePhone(phone);
    state = InviteAuthVerifying(code: currentState.code);

    try {
      await _repository.requestOtp(normalizedPhone);

      state = InviteAuthOtpSent(
        code: currentState.code,
        phone: normalizedPhone,
        firstName: currentState.firstName,
        tenantId: currentState.tenantId,
        sentAt: DateTime.now(),
      );
    } catch (e) {
      state = InviteAuthError(
        message: _parseError(e),
        isExpired: false,
        isUsed: false,
      );
    }
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    final currentState = state;
    if (currentState is! InviteAuthOtpSent) return;

    state = InviteAuthClaiming(code: currentState.code);

    try {
      await _repository.requestOtp(currentState.phone);

      state = InviteAuthOtpSent(
        code: currentState.code,
        phone: currentState.phone,
        firstName: currentState.firstName,
        tenantId: currentState.tenantId,
        sentAt: DateTime.now(),
      );
    } catch (e) {
      state = InviteAuthError(
        message: _parseError(e),
        isExpired: false,
        isUsed: false,
      );
    }
  }

  /// Claim invite with OTP verification
  Future<void> claimInvite(String otp) async {
    final currentState = state;
    if (currentState is! InviteAuthOtpSent) return;

    // Basic validation
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      state = const InviteAuthError(
        message: 'Please enter a valid 6-digit code',
        isExpired: false,
        isUsed: false,
      );
      return;
    }

    state = InviteAuthClaiming(code: currentState.code);

    try {
      final response = await _repository.claimInvite(
        currentState.code,
        currentState.phone,
        otp,
      );

      // Save the token
      if (response.token.isNotEmpty) {
        await _dioClient.saveTokens(
          accessToken: response.token,
          refreshToken: null,
        );
      }

      state = InviteAuthSuccess(
        driver: response.driver,
        tenantId: currentState.tenantId,
      );
    } catch (e) {
      final error = _parseInviteError(e);
      state = InviteAuthError(
        message: error.message,
        isExpired: error.isExpired,
        isUsed: error.isUsed,
      );
    }
  }

  ({String message, bool isExpired, bool isUsed}) _parseInviteError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('expired')) {
      return (
        message: 'This invite code has expired. Please contact your fleet manager.',
        isExpired: true,
        isUsed: false,
      );
    }
    if (errorStr.contains('already used') || errorStr.contains('already claimed')) {
      return (
        message: 'This invite code has already been used.',
        isExpired: false,
        isUsed: true,
      );
    }
    if (errorStr.contains('not found') || errorStr.contains('invalid')) {
      return (
        message: 'Invalid invite code. Please check and try again.',
        isExpired: false,
        isUsed: false,
      );
    }
    if (errorStr.contains('phone') && errorStr.contains('match')) {
      return (
        message: 'Phone number does not match the invite. Please use the number your fleet manager registered.',
        isExpired: false,
        isUsed: false,
      );
    }

    return (
      message: _parseError(error),
      isExpired: false,
      isUsed: false,
    );
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('Too many')) {
      return 'Too many attempts. Please try again later.';
    }
    if (errorStr.contains('rate') || errorStr.contains('429')) {
      return 'Too many requests. Please wait a moment.';
    }

    return 'An error occurred. Please try again.';
  }
}

/// Invite auth state provider
final inviteAuthStateProvider =
    StateNotifierProvider<InviteAuthNotifier, InviteAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final dioClient = ref.watch(dioClientProvider);

  return InviteAuthNotifier(
    repository: repository,
    authService: authService,
    dioClient: dioClient,
  );
});
