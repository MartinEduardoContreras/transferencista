import 'geo_point.dart';

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

  Duration get duration => departure.difference(arrival);
}
