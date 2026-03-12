import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/pwa_install_service.dart';

/// Banner widget prompting users to install the PWA
class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _showBanner = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkInstallable();
      PwaInstallService.instance.onInstallableChanged.listen((isInstallable) {
        if (mounted && !_dismissed) {
          setState(() => _showBanner = isInstallable);
        }
      });
    }
  }

  void _checkInstallable() {
    // Don't show if already installed
    if (PwaInstallService.instance.isInstalledPwa()) {
      return;
    }
    setState(() => _showBanner = PwaInstallService.instance.isInstallable);
  }

  Future<void> _handleInstall() async {
    final installed = await PwaInstallService.instance.promptInstall();
    if (mounted) {
      if (installed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App installed successfully!'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
      setState(() => _showBanner = false);
    }
  }

  void _dismiss() {
    setState(() {
      _showBanner = false;
      _dismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Install Relay Drivers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add to home screen for quick access',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _handleInstall,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Install'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _dismiss,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withAlpha(179),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Not now',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
