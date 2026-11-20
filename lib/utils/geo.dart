import 'dart:math' as math;

import '../models/geo_point.dart';

const _earthRadiusMeters = 6371000.0;

/// Distancia en metros entre dos puntos (fórmula de Haversine).
double distanceMeters(GeoPoint a, GeoPoint b) {
  double rad(double degrees) => degrees * math.pi / 180;

  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(h.toDouble()));
}
