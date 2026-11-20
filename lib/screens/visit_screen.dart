import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/geo_point.dart';
import '../models/pharmacy.dart';
import '../models/track_point.dart';
import '../models/visit.dart';
import '../models/visit_photo.dart';
import '../services/location_service.dart';
import '../services/movement_tracker.dart';
import '../utils/format.dart';

/// Radio en metros a partir del cual se avisa y se registra el trayecto.
const trackingRadiusMeters = 500.0;

/// Registro de la visita. Primero solo se ofrece el check-in GPS. Después aparecen
/// las fotos, la validación del punto, el inventario, la competencia y las observaciones.
/// Al iniciar, la persona acepta el registro de trayecto (con aviso visible).
/// El check-out GPS se pide al finalizar.
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
  final Set<PointOfSaleCheck> _checks = {};
  late final Map<String, TextEditingController> _inventory = {
    for (final product in widget.repository.portfolio)
      product: TextEditingController(),
  };
  final _competitors = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _trackingSub?.cancel();
    for (final controller in _inventory.values) {
      controller.dispose();
    }
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
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 70,
    );
    if (shot == null || !mounted) return;
    setState(() {
      _photos.removeWhere((p) => p.kind == kind);
      _photos.add(VisitPhoto(
        kind: kind,
        path: shot.path,
        takenAt: DateTime.now(),
      ));
    });
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
      photos: List.of(_photos),
      trackingConsent: _trackingConsent,
      track: _tracker?.points ?? const <TrackPoint>[],
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
