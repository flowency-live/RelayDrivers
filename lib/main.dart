import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/router/app_router.dart';
import 'core/design_system/theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/pwa_install_service.dart';
import 'core/services/push_notification_service.dart';
import 'features/jobs/application/jobs_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path URL strategy for web (removes the # from URLs)
  // This is CRITICAL for deep links with query parameters to work
  usePathUrlStrategy();

  // Initialize PWA install service for web
  if (kIsWeb) {
    PwaInstallService.instance.initialize();
  }

  runApp(
    const ProviderScope(
      child: RelayDriversApp(),
    ),
  );
}

/// Relay Drivers application root
class RelayDriversApp extends ConsumerStatefulWidget {
  const RelayDriversApp({super.key});

  @override
  ConsumerState<RelayDriversApp> createState() => _RelayDriversAppState();
}

class _RelayDriversAppState extends ConsumerState<RelayDriversApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Listen for system brightness changes
    WidgetsBinding.instance.addObserver(this);

    // Initialise push notifications on native platforms. Guarded so a missing
    // Firebase config (see FIREBASE_SETUP.md) never blocks startup. On a
    // new-job message the jobs list is refreshed so the driver sees the offer
    // without polling. Web PWA push is out of scope here.
    if (!kIsWeb) {
      Future.microtask(() async {
        final push = ref.read(pushNotificationServiceProvider);
        push.onJobsShouldRefresh =
            () => ref.read(jobsStateProvider.notifier).refresh();
        await push.initialize();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Rebuild when system brightness changes
    // This triggers providers that depend on platform brightness
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    // Get current platform brightness
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // Get the appropriate theme based on mode and platform brightness
    final theme = themeNotifier.getTheme(platformBrightness);

    return MaterialApp.router(
      title: 'Relay Drivers',
      debugShowCheckedModeBanner: false,
      theme: DesignTheme.light,
      darkTheme: DesignTheme.dark,
      themeMode: _getThemeMode(themeMode),
      routerConfig: router,
    );
  }

  ThemeMode _getThemeMode(AppThemeMode appThemeMode) {
    return switch (appThemeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}
