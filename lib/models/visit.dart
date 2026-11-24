import 'geo_point.dart';
import 'product_record.dart';
import 'track_point.dart';
import 'visit_photo.dart';

/// Registro de una visita a una farmacia.
class Visit {
  const Visit({
    required this.id,
    required this.pharmacyId,
    required this.arrival,
    required this.departure,
    this.products = const [],
    this.competitors = '',
    this.notes = '',
    this.checkIn,
    this.checkOut,
    this.photos = const [],
    this.trackingConsent = false,
    this.track = const [],
  });

  final String id;
  final String pharmacyId;

  /// Hora del check-in (llegada). Coincide con la ubicación de [checkIn].
  final DateTime arrival;
  final DateTime departure;

  /// Ubicación GPS al llegar y al salir de la farmacia.
  final GeoPoint? checkIn;
  final GeoPoint? checkOut;

  /// Productos revisados en esta visita, con lo que se encontró de cada uno.
  final List<ProductRecord> products;
  final String competitors;
  final String notes;

  /// Fotos de exhibición tomadas durante la visita.
  final List<VisitPhoto> photos;

  /// La transferencista aceptó el registro de trayecto al iniciar la visita.
  final bool trackingConsent;

  /// Puntos registrados cuando la persona se alejó más de 500 m de la farmacia.
  final List<TrackPoint> track;

  Duration get duration => departure.difference(arrival);
}
