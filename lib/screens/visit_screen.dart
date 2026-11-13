import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../models/visit.dart';
import '../utils/format.dart';

/// Registro de la visita: checklist del punto, inventario, competencia y notas.
///
/// Pendiente para fases siguientes (ver docs/FASES.md):
/// GPS de check-in/check-out, fotos antes/después, pedido sugerido y firma.
class VisitScreen extends StatefulWidget {
  const VisitScreen({
    super.key,
    required this.repository,
    required this.pharmacy,
  });

  final AppRepository repository;
  final Pharmacy pharmacy;

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  final DateTime _arrival = DateTime.now();
  final Set<PointOfSaleCheck> _checks = {};
  late final Map<String, TextEditingController> _inventory = {
    for (final product in widget.repository.portfolio)
      product: TextEditingController(),
  };
  final _competitors = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final controller in _inventory.values) {
      controller.dispose();
    }
    _competitors.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _toggle(PointOfSaleCheck check, bool? value) {
    setState(() {
      if (value == true) {
        _checks.add(check);
      } else {
        _checks.remove(check);
      }
    });
  }

  void _finish() {
    final inventory = <String, int>{};
    _inventory.forEach((product, controller) {
      final units = int.tryParse(controller.text.trim());
      if (units != null) inventory[product] = units;
    });

    final visit = Visit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pharmacyId: widget.pharmacy.id,
      arrival: _arrival,
      departure: DateTime.now(),
      checks: Set.of(_checks),
      inventory: inventory,
      competitors: _competitors.text.trim(),
      notes: _notes.text.trim(),
    );
    widget.repository.saveVisit(visit);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Visita · ${widget.pharmacy.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Llegada: ${formatTime(_arrival)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text('Validación en el punto', style: theme.textTheme.titleMedium),
          for (final check in PointOfSaleCheck.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(check.label),
              value: _checks.contains(check),
              onChanged: (value) => _toggle(check, value),
            ),
          const SizedBox(height: 16),
          Text('Inventario (unidades)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in _inventory.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _competitors,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Competencia (marcas, promociones, precios)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.check),
            label: const Text('Finalizar visita'),
          ),
        ],
      ),
    );
  }
}
