import 'package:material_ui/material_ui.dart';

import '../models/transfer.dart';

/// Formulario de una transferencia (pedido): producto de la lista, distribuidor
/// por donde se hace el pedido y cantidad solicitada. Al guardar devuelve el pedido.
class TransferScreen extends StatefulWidget {
  const TransferScreen({
    super.key,
    required this.catalog,
    required this.distributors,
  });

  final List<String> catalog;
  final List<String> distributors;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  String? _product;
  String? _distributor;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Transfer(
        product: _product!,
        distributor: _distributor!,
        quantity: int.parse(_quantity.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transferencia')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _product,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Producto *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final product in widget.catalog)
                  DropdownMenuItem(value: product, child: Text(product)),
              ],
              onChanged: (value) => setState(() => _product = value),
              validator: (v) => v == null ? 'Selecciona el producto' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _distributor,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Distribuidor *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final distributor in widget.distributors)
                  DropdownMenuItem(value: distributor, child: Text(distributor)),
              ],
              onChanged: (value) => setState(() => _distributor = value),
              validator: (v) => v == null ? 'Selecciona el distribuidor' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad solicitada *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final quantity = int.tryParse((v ?? '').trim());
                if (quantity == null || quantity < 1) {
                  return 'Escribe una cantidad mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar transferencia'),
            ),
          ],
        ),
      ),
    );
  }
}
