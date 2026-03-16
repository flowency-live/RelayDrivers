import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

/// Theme mode options
enum AppThemeMode {
  /// Follow system dark/light preference
  system,

  /// Force light mode
  light,

  /// Force dark mode
  dark,
}

/// State notifier for theme mode
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system);

  /// Set the theme mode
  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }

  /// Toggle between light and dark (ignores system)
  void toggleTheme() {
    final currentBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final effectiveBrightness = getEffectiveBrightness(currentBrightness);

    state = effectiveBrightness == Brightness.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
  }

  /// Get the effective brightness based on current mode
  Brightness getEffectiveBrightness(Brightness platformBrightness) {
    return switch (state) {
      AppThemeMode.system => platformBrightness,
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
    };
  }

  /// Get the appropriate theme data
  ThemeData getTheme(Brightness platformBrightness) {
    final effectiveBrightness = getEffectiveBrightness(platformBrightness);
    return effectiveBrightness == Brightness.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
  }

  /// Check if currently in dark mode
  bool isDarkMode(Brightness platformBrightness) {
    return getEffectiveBrightness(platformBrightness) == Brightness.dark;
  }
}

/// Provider for theme mode state
final themeModeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// Provider for the current effective brightness
/// This reacts to both user preference and system changes
final effectiveBrightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final platformBrightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  return switch (themeMode) {
    AppThemeMode.system => platformBrightness,
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
  };
});

/// Provider for the current theme data
final themeDataProvider = Provider<ThemeData>((ref) {
  final brightness = ref.watch(effectiveBrightnessProvider);
  return brightness == Brightness.dark
      ? AppTheme.darkTheme
      : AppTheme.lightTheme;
});

/// Provider to check if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final brightness = ref.watch(effectiveBrightnessProvider);
  return brightness == Brightness.dark;
});
