import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/api_config.dart';
import '../../features/auth/application/providers.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

/// Thin wrapper around `geolocator` for permission handling and a foreground
/// position stream. Location is only meaningful on native (mobile) targets;
/// on web the browser geolocation API is used by geolocator but background
/// tracking is not available, so callers should treat web as best-effort.
class LocationService {
  /// Request "while in use" location permission, prompting the user if needed.
  /// Returns true if we ended up with foreground (or better) permission.
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// A foreground position stream. Emits when the device moves more than
  /// [distanceFilterMeters]. Ping cadence is enforced separately by the
  /// tracking controller's timer.
  Stream<Position> positionStream({int distanceFilterMeters = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// One-shot current position.
  Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

/// Sends the driver's live location to the backend while a job is en_route or
/// arrived. Owns the position subscription and a throttling timer so we ping at
/// most once per [_pingInterval] regardless of stream cadence.
class LocationTrackingController {
  final LocationService _locationService;
  final DioClient _dioClient;

  LocationTrackingController({
    required LocationService locationService,
    required DioClient dioClient,
  })  : _locationService = locationService,
        _dioClient = dioClient;

  static const Duration _pingInterval = Duration(seconds: 20);

  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  String? _activeJobId;
  Position? _latest;

  bool get isTracking => _activeJobId != null;

  /// Begin tracking for [jobId]. No-op if already tracking that job.
  Future<void> startForJob(String jobId) async {
    if (_activeJobId == jobId) return;
    // Switching jobs: tear down the previous subscription first.
    await stop();

    final granted = await _locationService.ensurePermission();
    if (!granted) {
      AppLogger.debug('[Location] permission not granted; tracking skipped');
      return;
    }

    _activeJobId = jobId;

    try {
      _subscription = _locationService
          .positionStream()
          .listen((pos) => _latest = pos, onError: (Object e) {
        AppLogger.error('[Location] position stream error', e);
      });
    } catch (e) {
      AppLogger.error('[Location] failed to start position stream', e);
    }

    // Prime with a one-shot fix so the first ping is not empty.
    try {
      _latest = await _locationService.currentPosition();
      await _ping();
    } catch (e) {
      AppLogger.error('[Location] initial fix failed', e);
    }

    _timer = Timer.periodic(_pingInterval, (_) => _ping());
  }

  /// Stop tracking and release resources.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _subscription?.cancel();
    _subscription = null;
    _activeJobId = null;
    _latest = null;
  }

  Future<void> _ping() async {
    final jobId = _activeJobId;
    final pos = _latest;
    if (jobId == null || pos == null) return;

    // TODO(backend): POST /driver/jobs/{id}/location is not yet deployed
    // (see ApiConfig.jobLocation). Once the route exists this call will start
    // succeeding; until then failures are swallowed so tracking is a no-op
    // rather than a crash. Expected body documented on ApiConfig.jobLocation.
    try {
      await _dioClient.dio.post(
        ApiConfig.jobLocation(jobId),
        data: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'heading': pos.heading,
          'speed': pos.speed,
          'accuracy': pos.accuracy,
          'recordedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.debug('[Location] ping failed (endpoint may not exist yet): $e');
    }
  }
}

/// Location service provider.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Location tracking controller provider. Disposed with the container; also
/// stops tracking on dispose.
final locationTrackingProvider = Provider<LocationTrackingController>((ref) {
  final controller = LocationTrackingController(
    locationService: ref.watch(locationServiceProvider),
    dioClient: ref.watch(dioClientProvider),
  );
  ref.onDispose(controller.stop);
  return controller;
});

/// Whether location tracking is meaningfully supported on this target.
/// Web has no background tracking; treat it as best-effort foreground only.
bool get locationTrackingSupported => !kIsWeb;
