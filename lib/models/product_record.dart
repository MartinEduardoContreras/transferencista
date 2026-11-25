/// Lo que se registra de un producto durante una visita (paso 3 y 5 del proceso).
class ProductRecord {
  const ProductRecord({
    required this.product,
    this.displayed = false,
    this.priceVisible = false,
    this.productVisible = false,
    this.units = 0,
    this.competitionPresent = false,
    this.popPresent = false,
    this.outOfStock = false,
    this.photoPath,
  });

  final String product;

  /// Producto exhibido en el punto de venta.
  final bool displayed;
  final bool priceVisible;
  final bool productVisible;

  /// Unidades en inventario: 0 si no hay, 1 en adelante si hay.
  final int units;
  final bool competitionPresent;
  final bool popPresent;
  final bool outOfStock;

  /// Foto del producto en el punto de venta, tomada durante la visita. Opcional.
  final String? photoPath;
}

/// Último registro de un producto en una farmacia, con la visita en que se hizo.
class ProductHistoryEntry {
  const ProductHistoryEntry({required this.date, required this.record});

  final DateTime date;
  final ProductRecord record;
}
