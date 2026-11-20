import '../models/geo_point.dart';
import '../models/track_point.dart';
import '../utils/geo.dart';

/// Eventos que produce el seguimiento de trayecto para avisar a la interfaz.
enum TrackEvent {
  none,

  /// La persona acaba de salir del radio de 500 m: se muestra un aviso.
  leftRadius,

  /// Se registró un punto del trayecto (cada 10 minutos mientras esté fuera).
  logged,
}

/// Reglas del registro de trayecto durante una visita.
///
/// - Solo registra cuando la persona está a más de [radiusMeters] del check-in.
/// - Registra un punto al salir del radio y luego cada [interval] mientras siga fuera.
/// - Avisa una vez cada vez que cruza el radio hacia afuera.
///
/// Es transparente para la transferencista: el aviso y el consentimiento
/// se muestran en la app antes de iniciar el registro.
class MovementTracker {
  MovementTracker({
    required this.site,
    this.radiusMeters = 500,
    this.interval = const Duration(minutes: 10),
  });

  /// Ubicación del check-in de la farmacia.
  final GeoPoint site;
  final double radiusMeters;
  final Duration interval;

  final List<TrackPoint> _points = [];
  DateTime? _lastLogged;
  bool _outside = false;

  List<TrackPoint> get points => List.unmodifiable(_points);

  bool get isOutside => _outside;

  TrackEvent onPosition(GeoPoint position, DateTime now) {
    final distance = distanceMeters(site, position);
    final outside = distance > radiusMeters;
    var event = TrackEvent.none;

    if (outside && !_outside) {
      event = TrackEvent.leftRadius;
    }
    _outside = outside;

    if (outside) {
      final last = _lastLogged;
      if (last == null || now.difference(last) >= interval) {
        _points.add(TrackPoint(
          time: now,
          point: position,
          distanceFromSiteMeters: distance,
        ));
        _lastLogged = now;
        if (event == TrackEvent.none) event = TrackEvent.logged;
      }
    }
    return event;
  }
}
