/// Farmacia o punto de venta que atiende la transferencista.
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
    this.averageTicket = 0,
    this.topProduct,
    this.newProduct,
    this.recentProducts = const [],
    this.estimatedStock = const {},
  });

  final String id;
  final String name;

  /// Cadena o tipo: "Drogas La Rebaja", "Independiente", etc.
  final String chain;
  final String zone;
  final String address;

  /// Responsable de la farmacia (quien firma la visita).
  final String manager;

  /// 1 = mayor prioridad. Se usa para ordenar la ruta del día.
  final int priority;

  /// Null cuando la farmacia aún no tiene compras registradas.
  final int? daysSinceLastPurchase;
  final double averageTicket;
  final String? topProduct;
  final String? newProduct;
  final List<String> recentProducts;

  /// Inventario estimado por producto antes de la visita (unidades).
  final Map<String, int> estimatedStock;

  String get lastPurchaseLabel => daysSinceLastPurchase == null
      ? 'Sin compras registradas'
      : 'Hace $daysSinceLastPurchase días';
}
