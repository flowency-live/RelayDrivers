import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/pwa_install_service.dart';

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
class RelayDriversApp extends ConsumerWidget {
  const RelayDriversApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Relay Drivers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
