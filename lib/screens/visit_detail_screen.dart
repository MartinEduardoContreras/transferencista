import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/product_record.dart';
import '../models/visit.dart';
import '../models/visit_photo.dart';
import '../utils/format.dart';
import '../widgets/info_section.dart';
import '../widgets/brand_app_bar.dart';

/// Datos completos de una visita registrada.
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({
    super.key,
    required this.repository,
    required this.visit,
  });

  final AppRepository repository;
  final Visit visit;

  static String _yesNo(bool value) => value ? 'Sí' : 'No';

  /// Ruta de la foto de exhibición de [kind], o null si no se tomó.
  String? _photoPath(VisitPhotoKind kind) {
    for (final photo in visit.photos) {
      if (photo.kind == kind) return photo.path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pharmacy = repository.pharmacyById(visit.pharmacyId);

    return Scaffold(
      appBar: BrandAppBar(title: pharmacy?.name ?? 'Visita'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoSection(
            title: 'Tiempos',
            rows: [
              InfoRow('Fecha', formatDate(visit.arrival)),
              InfoRow('Llegada', formatTime(visit.arrival)),
              InfoRow('Salida', formatTime(visit.departure)),
              InfoRow('Duración', '${visit.duration.inMinutes} min'),
            ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Ubicación GPS',
            rows: [
              InfoRow('Check-in', visit.checkIn?.label ?? 'No registrado'),
              InfoRow('Check-out', visit.checkOut?.label ?? 'No registrado'),
            ],
          ),
          const SizedBox(height: 12),
          if (visit.products.isEmpty)
            const InfoSection(
              title: 'Productos',
              rows: [InfoRow('Sin productos', '—')],
            ),
          for (final record in visit.products) ...[
            _ProductSection(record: record),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto de exhibición',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PhotoBox(
                        label: 'Antes',
                        path: _photoPath(VisitPhotoKind.before),
                      ),
                      const SizedBox(width: 12),
                      _PhotoBox(
                        label: 'Después',
                        path: _photoPath(VisitPhotoKind.after),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Registro de trayecto',
            rows: [
              InfoRow(
                'Consentimiento',
                visit.trackingConsent ? 'Aceptado' : 'No aceptado',
              ),
              InfoRow('Puntos registrados', '${visit.track.length}'),
              for (final point in visit.track)
                InfoRow(
                  formatTime(point.time),
                  '${point.distanceFromSiteMeters.round()} m · ${point.point.label}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Transferencias',
            rows: visit.transfers.isEmpty
                ? [const InfoRow('Sin transferencias', '—')]
                : [
                    for (final transfer in visit.transfers)
                      InfoRow(
                        transfer.product,
                        '${transfer.distributor} · ${transfer.quantity} unidades',
                      ),
                  ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Competencia y observaciones',
            rows: [
              InfoRow(
                'Competencia',
                visit.competitors.isEmpty ? '—' : visit.competitors,
              ),
              InfoRow('Observaciones', visit.notes.isEmpty ? '—' : visit.notes),
            ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Firma del responsable',
            rows: [
              InfoRow(
                'Nombre',
                visit.signerName.isEmpty ? '—' : visit.signerName,
              ),
            ],
          ),
          if (visit.signaturePath != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.white,
                child: Image.file(File(visit.signaturePath!), fit: BoxFit.contain),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Recuadro de una foto de exhibición (Antes o Después). Si no hay foto, queda en blanco.
class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label, required this.path});

  final String label;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = path;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: file == null
                    ? null
                    : Image.file(File(file), fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.record});

  final ProductRecord record;

  @override
  Widget build(BuildContext context) {
    final photo = record.photoPath;
    // La foto va dentro de la tarjeta del producto, debajo de sus datos.
    return InfoSection(
      title: record.product,
      rows: [
        InfoRow('Exhibido', VisitDetailScreen._yesNo(record.displayed)),
        InfoRow('Precio visible', VisitDetailScreen._yesNo(record.priceVisible)),
        InfoRow('Producto visible', VisitDetailScreen._yesNo(record.productVisible)),
        InfoRow('Inventario', '${record.units} unidades'),
        InfoRow('Hay competencia', VisitDetailScreen._yesNo(record.competitionPresent)),
        InfoRow('Material POP', VisitDetailScreen._yesNo(record.popPresent)),
        InfoRow('Hay agotados', VisitDetailScreen._yesNo(record.outOfStock)),
      ],
      footer: photo == null
          ? null
          : SizedBox(
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(photo), fit: BoxFit.cover),
                ),
              ),
            ),
    );
  }
}
