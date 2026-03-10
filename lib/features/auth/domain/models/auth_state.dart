import 'driver_user.dart';

/// Authentication state - discriminated union for type-safe state handling
sealed class AuthState {
  const AuthState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(DriverUser user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    return switch (this) {
      AuthInitial() => initial(),
      AuthLoading() => loading(),
      AuthAuthenticated(:final user) => authenticated(user),
      AuthUnauthenticated() => unauthenticated(),
      AuthError(:final message) => error(message),
    };
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(DriverUser user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      AuthInitial() => initial?.call() ?? orElse(),
      AuthLoading() => loading?.call() ?? orElse(),
      AuthAuthenticated(:final user) => authenticated?.call(user) ?? orElse(),
      AuthUnauthenticated() => unauthenticated?.call() ?? orElse(),
      AuthError(:final message) => error?.call(message) ?? orElse(),
    };
  }
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final DriverUser user;
  const AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}
