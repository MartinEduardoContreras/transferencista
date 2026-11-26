import 'package:material_ui/material_ui.dart';

import '../models/product_record.dart';

/// Elige un producto del catálogo que se encontró en la farmacia y su cantidad.
/// Solo muestra los productos que todavía no están en la visita. Al elegir uno,
/// devuelve su registro con la cantidad; los demás datos se completan después.
class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({
    super.key,
    required this.catalog,
    required this.registered,
  });

  final List<String> catalog;

  /// Productos que ya están en la visita y no se vuelven a agregar.
  final Set<String> registered;

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  String _query = '';

  Future<void> _pick(String product) async {
    final units = await showDialog<int>(
      context: context,
      builder: (_) => _UnitsDialog(product: product),
    );
    if (units == null || !mounted) return;
    Navigator.of(context).pop(ProductRecord(product: product, units: units));
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final product in widget.catalog)
        if (!widget.registered.contains(product) &&
            product.toLowerCase().contains(_query.toLowerCase()))
          product,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: options.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay productos disponibles con ese nombre.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final product in options)
                        ListTile(
                          title: Text(product),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _pick(product),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pide la cantidad encontrada del producto. Devuelve el número de unidades.
class _UnitsDialog extends StatefulWidget {
  const _UnitsDialog({required this.product});

  final String product;

  @override
  State<_UnitsDialog> createState() => _UnitsDialogState();
}

class _UnitsDialogState extends State<_UnitsDialog> {
  final _controller = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final units = int.tryParse(_controller.text.trim());
    if (units == null || units < 0) {
      setState(() => _error = 'Escribe 0 o un número mayor');
      return;
    }
    Navigator.of(context).pop(units);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Cantidad encontrada (unidades)',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Agregar')),
      ],
    );
  }
}
