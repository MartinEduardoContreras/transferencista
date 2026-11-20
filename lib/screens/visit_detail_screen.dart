import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/visit.dart';
import '../utils/format.dart';
import '../widgets/info_section.dart';

/// Datos completos de una visita registrada.
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({
    super.key,
    required this.repository,
    required this.visit,
  });

  final AppRepository repository;
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final pharmacy = repository.pharmacyById(visit.pharmacyId);

    return Scaffold(
      appBar: AppBar(title: Text(pharmacy?.name ?? 'Visita')),
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
          InfoSection(
            title: 'Validación en el punto',
            rows: [
              for (final check in PointOfSaleCheck.values)
                InfoRow(check.label, visit.checks.contains(check) ? 'Sí' : 'No'),
            ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Inventario encontrado',
            rows: visit.inventory.isEmpty
                ? [const InfoRow('Sin datos', '—')]
                : [
                    for (final entry in visit.inventory.entries)
                      InfoRow(entry.key, '${entry.value} unidades'),
                  ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Fotos',
            rows: visit.photos.isEmpty
                ? [const InfoRow('Sin fotos', '—')]
                : [
                    for (final photo in visit.photos)
                      InfoRow(
                        photo.kind.label,
                        formatTime(photo.takenAt),
                      ),
                  ],
          ),
          if (visit.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (final photo in visit.photos) ...[
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(photo.path), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
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
            title: 'Competencia y observaciones',
            rows: [
              InfoRow(
                'Competencia',
                visit.competitors.isEmpty ? '—' : visit.competitors,
              ),
              InfoRow('Observaciones', visit.notes.isEmpty ? '—' : visit.notes),
            ],
          ),
        ],
      ),
    );
  }
}
