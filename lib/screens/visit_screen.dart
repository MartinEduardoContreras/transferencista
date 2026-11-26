import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../data/distributors.dart';
import '../models/geo_point.dart';
import '../models/pharmacy.dart';
import '../models/product_record.dart';
import '../models/track_point.dart';
import '../models/transfer.dart';
import '../models/visit.dart';
import '../models/visit_photo.dart';
import '../services/location_service.dart';
import '../services/movement_tracker.dart';
import '../services/photo_storage.dart';
import '../utils/format.dart';
import 'product_check_screen.dart';
import 'product_picker_screen.dart';
import 'transfer_screen.dart';

/// Radio en metros a partir del cual se avisa y se registra el trayecto.
const trackingRadiusMeters = 500.0;

/// Registro de la visita. Primero solo se ofrece el check-in GPS. Después aparecen
/// las fotos, los productos encontrados, las transferencias (pedidos), la
/// competencia y las observaciones. Al iniciar, la persona acepta el registro de
/// trayecto (con aviso visible). El check-out GPS se pide al finalizar.
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

  bool _trackingConsent = false;
  MovementTracker? _tracker;
  StreamSubscription<GeoPoint>? _trackingSub;
  bool _outsideRadius = false;

  final List<VisitPhoto> _photos = [];

  /// Productos encontrados, indexados por nombre. El orden es el de registro.
  final Map<String, ProductRecord> _records = {};
  final List<Transfer> _transfers = [];
  final _competitors = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _trackingSub?.cancel();
    _competitors.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    if (!result.isSuccess) {
      _showMessage(locationFailureMessage(result.failure!));
      return;
    }
    setState(() {
      _arrival = DateTime.now();
      _checkIn = result.point;
    });
    await _askTrackingConsent();
  }

  /// Muestra el aviso del registro de trayecto. Solo se inicia si la persona acepta.
  Future<void> _askTrackingConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registro de trayecto'),
        content: const Text(
          'Durante esta visita registraremos tu posición cada 10 minutos '
          'mientras estés a más de 500 m de la farmacia, con fines de control '
          'de la visita. Te avisaremos cuando te alejes. Puedes ver estos datos '
          'en el detalle de la visita.\n\n'
          'Si no aceptas, la visita continúa sin registro de trayecto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No acepto'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Acepto'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _trackingConsent = accepted ?? false);
    if (_trackingConsent) _startTracking();
  }

  void _startTracking() {
    final site = _checkIn;
    if (site == null) return;
    _tracker = MovementTracker(site: site);
    _trackingSub = widget.locationService.watchPositions().listen((position) {
      final event = _tracker!.onPosition(position, DateTime.now());
      if (!mounted) return;
      if (event == TrackEvent.leftRadius) {
        _showMessage('Te alejaste más de 500 m de la farmacia.');
      }
      setState(() => _outsideRadius = _tracker!.isOutside);
    });
  }

  Future<void> _takePhoto(VisitPhotoKind kind) async {
    final savedPath = await takeVisitPhoto(kind.name);
    if (savedPath == null || !mounted) return;

    setState(() {
      _photos.removeWhere((photo) => photo.kind == kind);
      _photos.add(VisitPhoto(
        kind: kind,
        path: savedPath,
        takenAt: DateTime.now(),
      ));
    });
  }

  /// Agrega un producto encontrado que todavía no está en la visita.
  Future<void> _addProduct() async {
    final record = await Navigator.of(context).push<ProductRecord>(
      MaterialPageRoute(
        builder: (_) => ProductPickerScreen(
          catalog: widget.repository.catalog,
          registered: _records.keys.toSet(),
        ),
      ),
    );
    if (record != null && mounted) {
      setState(() => _records[record.product] = record);
    }
  }

  /// Completa o corrige el registro de un producto ya agregado.
  Future<void> _openProduct(String product) async {
    final result = await Navigator.of(context).push<ProductRecord>(
      MaterialPageRoute(
        builder: (_) => ProductCheckScreen(
          product: product,
          initial: _records[product],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _records[product] = result);
    }
  }

  Future<void> _addTransfer() async {
    final transfer = await Navigator.of(context).push<Transfer>(
      MaterialPageRoute(
        builder: (_) => TransferScreen(
          catalog: widget.repository.catalog,
          distributors: distributors,
        ),
      ),
    );
    if (transfer != null && mounted) {
      setState(() => _transfers.add(transfer));
    }
  }

  Future<void> _finish() async {
    final result = await _readLocation();
    if (!mounted) return;
    if (!result.isSuccess) {
      // Sin check-out no se guarda la visita: la ubicación de salida es evidencia.
      _showMessage(locationFailureMessage(result.failure!));
      return;
    }

    _trackingSub?.cancel();
    _trackingSub = null;

    final visit = Visit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pharmacyId: widget.pharmacy.id,
      arrival: _arrival!,
      departure: DateTime.now(),
      products: _records.values.toList(),
      transfers: List.of(_transfers),
      competitors: _competitors.text.trim(),
      notes: _notes.text.trim(),
      checkIn: _checkIn,
      checkOut: result.point,
      photos: List.of(_photos),
      trackingConsent: _trackingConsent,
      track: _tracker?.points ?? const <TrackPoint>[],
    );
    await widget.repository.saveVisit(visit);
    if (!mounted) return;
    _showMessage('Visita registrada');
    // Vuelve a la primera pantalla (Hoy) y cierra la farmacia y la visita.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  VisitPhoto? _photoOf(VisitPhotoKind kind) {
    for (final photo in _photos) {
      if (photo.kind == kind) return photo;
    }
    return null;
  }

  Widget _photoSlot(VisitPhotoKind kind) {
    final photo = _photoOf(kind);
    return Expanded(
      child: Column(
        children: [
          Text(kind.label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photo == null
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.photo_camera_outlined)),
                    )
                  : Image.file(File(photo.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _takePhoto(kind),
            icon: const Icon(Icons.photo_camera),
            label: Text(photo == null ? 'Tomar foto' : 'Repetir foto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedIn = _checkIn != null;
    final records = _records.values.toList();

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
                    if (_trackingConsent)
                      Text(
                        _outsideRadius
                            ? 'Trayecto: fuera del radio de 500 m'
                            : 'Trayecto: dentro del radio de 500 m',
                        style: theme.textTheme.bodySmall,
                      ),
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
            Text('Fotos de exhibición', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _photoSlot(VisitPhotoKind.before),
                const SizedBox(width: 12),
                _photoSlot(VisitPhotoKind.after),
              ],
            ),
            const SizedBox(height: 16),
            Text('Productos en esta visita', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Agrega los productos que encuentres con su cantidad. '
              'Toca uno para completar o corregir sus datos.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aún no hay productos registrados.'),
              ),
            for (final record in records)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(record.product),
                  subtitle: Text(
                    '${record.units} unidades registradas'
                    '${record.photoPath != null ? ' · con foto' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openProduct(record.product),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
            const SizedBox(height: 16),
            Text('Transferencias', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pedidos de la farmacia: producto, distribuidor y cantidad. '
              'Puedes registrar varios.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_transfers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aún no hay transferencias.'),
              ),
            for (var i = 0; i < _transfers.length; i++)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(_transfers[i].product),
                  subtitle: Text(
                    '${_transfers[i].distributor} · '
                    '${_transfers[i].quantity} unidades',
                  ),
                  trailing: IconButton(
                    tooltip: 'Quitar transferencia',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _transfers.removeAt(i)),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _addTransfer,
              icon: const Icon(Icons.add),
              label: const Text('Agregar transferencia'),
            ),
            const SizedBox(height: 16),
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
