import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/geo_point.dart';
import '../models/pharmacy.dart';
import '../models/visit.dart';
import '../services/location_service.dart';
import '../utils/format.dart';

/// Registro de la visita. Primero solo se ofrece el check-in GPS; después del
/// check-in aparecen la validación del punto, el inventario, la competencia y
/// las observaciones. El check-out GPS se pide al finalizar.
///
/// Pendiente para fases siguientes (ver docs/FASES.md):
/// fotos antes/después, pedido sugerido, firma y validación de distancia.
class VisitScreen extends StatefulWidget {
  const VisitScreen({
    super.key,
    required this.repository,
    required this.pharmacy,
    required this.locationService,
  });

  final AppRepository repository;
  final Pharmacy pharmacy;
  final LocationService locationService;

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  DateTime? _arrival;
  GeoPoint? _checkIn;
  bool _busy = false;

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

  void _showError(LocationFailure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(locationFailureMessage(failure))),
    );
  }

  Future<LocationResult> _readLocation() async {
    setState(() => _busy = true);
    final result = await widget.locationService.currentPosition();
    if (mounted) setState(() => _busy = false);
    return result;
  }

  Future<void> _doCheckIn() async {
    final result = await _readLocation();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _arrival = DateTime.now();
        _checkIn = result.point;
      });
    } else {
      _showError(result.failure!);
    }
  }

  Future<void> _finish() async {
    final result = await _readLocation();
    if (!mounted) return;
    if (!result.isSuccess) {
      // Sin check-out no se guarda la visita: la ubicación de salida es evidencia.
      _showError(result.failure!);
      return;
    }

    final inventory = <String, int>{};
    _inventory.forEach((product, controller) {
      final units = int.tryParse(controller.text.trim());
      if (units != null) inventory[product] = units;
    });

    final visit = Visit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pharmacyId: widget.pharmacy.id,
      arrival: _arrival!,
      departure: DateTime.now(),
      checks: Set.of(_checks),
      inventory: inventory,
      competitors: _competitors.text.trim(),
      notes: _notes.text.trim(),
      checkIn: _checkIn,
      checkOut: result.point,
    );
    widget.repository.saveVisit(visit);
    Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedIn = _checkIn != null;

    return Scaffold(
      appBar: AppBar(title: Text('Visita · ${widget.pharmacy.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-in', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (checkedIn) ...[
                    Text('Llegada: ${formatTime(_arrival!)}'),
                    Text('Ubicación: ${_checkIn!.label}'),
                  ] else
                    const Text('Registra tu llegada con el GPS del teléfono.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy || checkedIn ? null : _doCheckIn,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      checkedIn ? 'Llegada registrada' : 'Registrar llegada',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (checkedIn) ...[
            const SizedBox(height: 16),
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
              onPressed: _busy ? null : _finish,
              icon: const Icon(Icons.check),
              label: Text(_busy ? 'Obteniendo ubicación…' : 'Finalizar visita'),
            ),
          ],
        ],
      ),
    );
  }
}
