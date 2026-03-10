import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/auth_state.dart';
import '../domain/models/driver_user.dart';
import '../domain/models/login_request.dart';
import '../domain/services/auth_service.dart';
import '../infrastructure/auth_repository.dart';

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
