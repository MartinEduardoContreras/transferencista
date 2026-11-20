import 'geo_point.dart';
import 'track_point.dart';
import 'visit_photo.dart';

/// Ítems del checklist de validación en el punto de venta (paso 3 del proceso).
enum PointOfSaleCheck {
  productDisplayed('Producto exhibido'),
  priceVisible('Precio visible'),
  productVisible('Producto visible'),
  hasStock('Tiene inventario'),
  competitionPresent('Hay competencia'),
  popMaterialPresent('Material POP presente'),
  hasOutOfStock('Hay agotados');

  const PointOfSaleCheck(this.label);

  final String label;
}

/// Registro de una visita a una farmacia.
class Visit {
  const Visit({
    required this.id,
    required this.pharmacyId,
    required this.arrival,
    required this.departure,
    required this.checks,
    required this.inventory,
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

  /// Checks marcados como cumplidos durante la visita.
  final Set<PointOfSaleCheck> checks;

  /// Unidades encontradas por producto del portafolio.
  final Map<String, int> inventory;
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
