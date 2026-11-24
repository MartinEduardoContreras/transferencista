import 'package:material_ui/material_ui.dart';

import '../models/product_record.dart';

/// Registro de un producto durante la visita: exhibición, precio, visibilidad,
/// inventario, competencia, material POP y agotados.
class ProductCheckScreen extends StatefulWidget {
  const ProductCheckScreen({super.key, required this.product, this.initial});

  final String product;

  /// Registro previo del mismo producto en esta visita, para poder corregirlo.
  final ProductRecord? initial;

  @override
  State<ProductCheckScreen> createState() => _ProductCheckScreenState();
}

class _ProductCheckScreenState extends State<ProductCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _displayed = widget.initial?.displayed ?? false;
  late bool _priceVisible = widget.initial?.priceVisible ?? false;
  late bool _productVisible = widget.initial?.productVisible ?? false;
  late bool _competition = widget.initial?.competitionPresent ?? false;
  late bool _pop = widget.initial?.popPresent ?? false;
  late bool _outOfStock = widget.initial?.outOfStock ?? false;
  late final _units = TextEditingController(
    text: '${widget.initial?.units ?? 0}',
  );

  @override
  void dispose() {
    _units.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProductRecord(
        product: widget.product,
        displayed: _displayed,
        priceVisible: _priceVisible,
        productVisible: _productVisible,
        units: int.parse(_units.text.trim()),
        competitionPresent: _competition,
        popPresent: _pop,
        outOfStock: _outOfStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Exhibido'),
              value: _displayed,
              onChanged: (v) => setState(() => _displayed = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Precio visible'),
              value: _priceVisible,
              onChanged: (v) => setState(() => _priceVisible = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Producto visible'),
              value: _productVisible,
              onChanged: (v) => setState(() => _productVisible = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _units,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tiene inventario (unidades) *',
                helperText: '0 si no hay; 1 en adelante si hay',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final units = int.tryParse((v ?? '').trim());
                if (units == null || units < 0) {
                  return 'Escribe 0 o un número mayor';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hay competencia'),
              value: _competition,
              onChanged: (v) => setState(() => _competition = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Material POP presente'),
              value: _pop,
              onChanged: (v) => setState(() => _pop = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hay agotados'),
              value: _outOfStock,
              onChanged: (v) => setState(() => _outOfStock = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Guardar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
