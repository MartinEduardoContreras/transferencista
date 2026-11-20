import 'geo_point.dart';

/// Punto del trayecto registrado durante la visita, cuando la persona
/// se aleja más de 500 m de la farmacia. Se guarda cada 10 minutos.
class TrackPoint {
  const TrackPoint({
    required this.time,
    required this.point,
    required this.distanceFromSiteMeters,
  });

  final DateTime time;
  final GeoPoint point;

  /// Distancia en metros entre este punto y el check-in de la farmacia.
  final double distanceFromSiteMeters;
}
