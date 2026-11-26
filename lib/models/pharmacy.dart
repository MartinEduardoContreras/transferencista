/// Farmacia o punto de venta que atiende la transferencista.
///
/// Solo guarda lo que identifica a la farmacia. Lo que cambia con cada visita o
/// compra (productos, historial) se obtiene de las visitas registradas.
class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.chain,
    required this.zone,
    required this.priority,
    this.address = '',
    this.manager = '',
    this.daysSinceLastPurchase,
  });

  final String id;
  final String name;

  /// Cadena o tipo: "Drogas La Rebaja", "Independiente", etc.
  final String chain;
  final String zone;
  final String address;

  /// Responsable de la farmacia (quien firma la visita).
  final String manager;

  /// Número guardado de la prioridad de ruta: 1 = la más alta. Se usa para
  /// ordenar la ruta del día. En pantalla se muestra con [RoutePriority].
  final int priority;

  /// Prioridad de ruta en la escala de 5 pasos que ve la persona.
  RoutePriority get routePriority => RoutePriority.fromRank(priority);

  /// Null cuando la farmacia aún no tiene compras registradas.
  final int? daysSinceLastPurchase;

  String get lastPurchaseLabel => daysSinceLastPurchase == null
      ? 'Sin compras registradas'
      : 'Hace $daysSinceLastPurchase días';
}

/// Prioridad de la farmacia en la ruta, en escala de baja a alta (5 pasos).
///
/// [rank] es el número que se guarda: 1 = la más alta, para ordenar la ruta.
enum RoutePriority {
  muyBaja('Muy baja', 5),
  baja('Baja', 4),
  media('Media', 3),
  alta('Alta', 2),
  muyAlta('Muy alta', 1);

  const RoutePriority(this.label, this.rank);

  final String label;
  final int rank;

  /// Prioridad para un número guardado. Valores fuera de 1..5 se toman como media.
  static RoutePriority fromRank(int rank) => values.firstWhere(
        (p) => p.rank == rank,
        orElse: () => media,
      );
}
