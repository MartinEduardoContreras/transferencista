import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../widgets/brand_app_bar.dart';

/// Cadenas o tipos de farmacia que aparecen en el proceso del documento.
const pharmacyChains = <String>[
  'Independiente',
  'Drogas La Rebaja',
  'Cruz Verde',
  'Farmatodo',
  'Cafam',
  'Colsubsidio',
  'Otra',
];

/// Formulario para crear una farmacia nueva. Al guardar devuelve la farmacia creada.
class NewPharmacyScreen extends StatefulWidget {
  const NewPharmacyScreen({super.key, required this.repository});

  final AppRepository repository;

  @override
  State<NewPharmacyScreen> createState() => _NewPharmacyScreenState();
}

class _NewPharmacyScreenState extends State<NewPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _zone = TextEditingController();
  final _address = TextEditingController();
  final _manager = TextEditingController();

  String? _chain;
  int _priority = 3;

  @override
  void dispose() {
    _name.dispose();
    _zone.dispose();
    _address.dispose();
    _manager.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pharmacy = Pharmacy(
      id: widget.repository.newPharmacyId(),
      name: _name.text.trim(),
      chain: _chain!,
      zone: _zone.text.trim(),
      address: _address.text.trim(),
      manager: _manager.text.trim(),
      priority: _priority,
    );
    await widget.repository.addPharmacy(pharmacy);
    if (!mounted) return;
    Navigator.of(context).pop(pharmacy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(title: 'Nueva farmacia'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la farmacia *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  _required(v, 'Escribe el nombre de la farmacia'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _chain,
              decoration: const InputDecoration(
                labelText: 'Cadena o tipo *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final chain in pharmacyChains)
                  DropdownMenuItem(value: chain, child: Text(chain)),
              ],
              onChanged: (value) => setState(() => _chain = value),
              validator: (v) => v == null ? 'Selecciona la cadena' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zone,
              decoration: const InputDecoration(
                labelText: 'Zona *',
                hintText: 'Ej. Zona Norte Bogotá',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _required(v, 'Escribe la zona'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _manager,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Responsable de la farmacia',
                helperText: 'Quien firma la visita',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Prioridad en la ruta *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 · más alta')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3 · media')),
                DropdownMenuItem(value: 4, child: Text('4')),
                DropdownMenuItem(value: 5, child: Text('5 · más baja')),
              ],
              onChanged: (value) =>
                  setState(() => _priority = value ?? _priority),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los productos y el historial de compras se registran en cada visita.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _save(),
              icon: const Icon(Icons.save),
              label: const Text('Guardar farmacia'),
            ),
          ],
        ),
      ),
    );
  }
}
