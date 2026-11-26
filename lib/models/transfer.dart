/// Pedido que la transferencista registra durante la visita: producto de la lista,
/// distribuidor por donde se hace el pedido y cantidad solicitada.
class Transfer {
  const Transfer({
    required this.product,
    required this.distributor,
    required this.quantity,
  });

  final String product;
  final String distributor;
  final int quantity;
}
