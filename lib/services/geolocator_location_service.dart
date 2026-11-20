import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import 'location_service.dart';

/// GPS real del dispositivo (Android e iOS), usando el paquete geolocator.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failure(LocationFailure.servicesDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        LocationFailure.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult.failure(LocationFailure.permissionDenied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult.success(
        GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
        ),
      );
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }

  @override
  Stream<GeoPoint> watchPositions() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
    // En Android muestra una notificación persistente mientras se registra el trayecto,
    // para que la transferencista siempre sepa que está activo.
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Transferencista: registro de trayecto activo',
        notificationText:
            'Se registra tu posición durante la visita. Te avisaremos si te alejas más de 500 m.',
        enableWakeLock: true,
      ),
    );
    final iosSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
      allowBackgroundLocationUpdates: true,
      showBackgroundLocationIndicator: true,
    );

    final effective = switch (defaultTargetPlatform) {
      TargetPlatform.android => androidSettings,
      TargetPlatform.iOS => iosSettings,
      _ => settings,
    };
    return Geolocator.getPositionStream(
      locationSettings: effective,
    ).map(
      (position) => GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      ),
    );
  }
}
