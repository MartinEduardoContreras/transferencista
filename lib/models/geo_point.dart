/// Coordenada GPS registrada en el check-in o check-out de una visita.
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Precisión reportada por el dispositivo, en metros.
  final double accuracyMeters;

  /// Texto corto para mostrar en pantalla: 4.60971, -74.08175 (±12 m)
  String get label =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)} '
      '(±${accuracyMeters.round()} m)';
}
