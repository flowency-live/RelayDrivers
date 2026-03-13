import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Service to handle PWA install prompt
class PwaInstallService {
  static PwaInstallService? _instance;
  static PwaInstallService get instance => _instance ??= PwaInstallService._();

  PwaInstallService._();

  bool _isInstallable = false;
  bool get isInstallable => _isInstallable;

  JSObject? _deferredPrompt;

  final _installableController = StreamController<bool>.broadcast();
  Stream<bool> get onInstallableChanged => _installableController.stream;

  /// Initialize the PWA install listener (call once at app start)
  void initialize() {
    if (!kIsWeb) return;

    // Listen for beforeinstallprompt event
    web.window.addEventListener(
      'beforeinstallprompt',
      ((web.Event e) {
        e.preventDefault();
        _deferredPrompt = e as JSObject;
        _isInstallable = true;
        _installableController.add(true);
      }).toJS,
    );

    // Listen for app installed event
    web.window.addEventListener(
      'appinstalled',
      ((web.Event e) {
        _deferredPrompt = null;
        _isInstallable = false;
        _installableController.add(false);
      }).toJS,
    );
  }

  /// Show the install prompt
  Future<bool> promptInstall() async {
    if (!kIsWeb || _deferredPrompt == null) {
      return false;
    }

    try {
      // Call prompt() on the deferred event using unsafe interop
      final promptMethod = _deferredPrompt!['prompt'];
      if (promptMethod != null) {
        (promptMethod as JSFunction).callAsFunction(_deferredPrompt);
      }

      // Wait for user choice
      final userChoicePromise = _deferredPrompt!['userChoice'];
      if (userChoicePromise != null) {
        final result = await (userChoicePromise as JSPromise).toDart;
        final outcome = (result as JSObject)['outcome'];
        _deferredPrompt = null;
        _isInstallable = false;
        _installableController.add(false);
        return outcome?.toString() == 'accepted';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if app is already installed (standalone mode)
  bool isInstalledPwa() {
    if (!kIsWeb) return false;

    final displayMode = web.window.matchMedia('(display-mode: standalone)');
    return displayMode.matches;
  }

  void dispose() {
    _installableController.close();
  }
}
