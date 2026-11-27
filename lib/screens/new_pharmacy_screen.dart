import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../widgets/brand_app_bar.dart';

/// Cadena o tipo de farmacia que se puede elegir al crear o editar.
const pharmacyChains = <String>[
  'Independiente',
  'De cadena',
  'Otra',
];

/// Formulario para crear una farmacia nueva o editar una existente. Si se pasa
/// [pharmacy], los campos se llenan con sus datos y se actualiza en lugar de
/// crear. Al guardar devuelve la farmacia guardada.
class NewPharmacyScreen extends StatefulWidget {
  const NewPharmacyScreen({super.key, required this.repository, this.pharmacy});

  final AppRepository repository;
  final Pharmacy? pharmacy;

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
  RoutePriority _priority = RoutePriority.media;

  bool get _isEditing => widget.pharmacy != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pharmacy;
    if (p != null) {
      _name.text = p.name;
      _zone.text = p.zone;
      _address.text = p.address;
      _manager.text = p.manager;
      _chain = p.chain;
      _priority = p.routePriority;
    }
  }

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

    final previous = widget.pharmacy;
    final pharmacy = Pharmacy(
      id: previous?.id ?? widget.repository.newPharmacyId(),
      name: _name.text.trim(),
      chain: _chain!,
      zone: _zone.text.trim(),
      address: _address.text.trim(),
      manager: _manager.text.trim(),
      priority: _priority.rank,
      daysSinceLastPurchase: previous?.daysSinceLastPurchase,
    );
    if (previous == null) {
      await widget.repository.addPharmacy(pharmacy);
    } else {
      await widget.repository.updatePharmacy(pharmacy);
    }
    if (!mounted) return;
    Navigator.of(context).pop(pharmacy);
  }

  @override
  Widget build(BuildContext context) {
    // Si la cadena guardada ya no está en la lista, se agrega para no perderla.
    final chains = [
      ...pharmacyChains,
      if (_chain != null && !pharmacyChains.contains(_chain)) _chain!,
    ];

    return Scaffold(
      appBar: BrandAppBar(
        title: _isEditing ? 'Editar farmacia' : 'Nueva farmacia',
      ),
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
                for (final chain in chains)
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
            DropdownButtonFormField<RoutePriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Prioridad en la ruta *',
                helperText: 'De baja a alta',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final priority in RoutePriority.values)
                  DropdownMenuItem(value: priority, child: Text(priority.label)),
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
              label: Text(_isEditing ? 'Guardar cambios' : 'Guardar farmacia'),
            ),
          ],
        ),
      ),
    );
  }
}
