import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../models/visit.dart';
import '../utils/format.dart';
import '../widgets/info_section.dart';
import 'visit_screen.dart';

/// Preparación antes de la visita: qué sabe la transferencista del cliente.
class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({
    super.key,
    required this.repository,
    required this.pharmacy,
  });

  final AppRepository repository;
  final Pharmacy pharmacy;

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  Future<void> _startVisit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitScreen(
          repository: widget.repository,
          pharmacy: widget.pharmacy,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita registrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pharmacy;
    final lastVisit = widget.repository.lastVisit(p);
    final notPurchased = widget.repository.portfolio
        .where((product) => !p.recentProducts.contains(product))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoSection(
            title: 'Información del cliente',
            rows: [
              InfoRow('Cadena', p.chain),
              InfoRow('Zona', p.zone),
              InfoRow('Última compra', p.lastPurchaseLabel),
              InfoRow('Ticket promedio', formatCop(p.averageTicket)),
            ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Productos',
            rows: [
              InfoRow('Producto estrella', p.topProduct ?? '—'),
              InfoRow('Producto nuevo', p.newProduct ?? '—'),
              InfoRow(
                'Comprados recientemente',
                p.recentProducts.isEmpty ? '—' : p.recentProducts.join(', '),
              ),
              InfoRow(
                'No comprados',
                notPurchased.isEmpty ? '—' : notPurchased.join(', '),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoSection(
            title: 'Inventario estimado',
            rows: p.estimatedStock.isEmpty
                ? [const InfoRow('Sin datos', '—')]
                : [
                    for (final entry in p.estimatedStock.entries)
                      InfoRow(entry.key, '${entry.value} unidades'),
                  ],
          ),
          if (lastVisit != null) ...[
            const SizedBox(height: 12),
            InfoSection(
              title: 'Última visita',
              rows: [
                InfoRow('Fecha', formatTime(lastVisit.arrival)),
                InfoRow('Duración', '${lastVisit.duration.inMinutes} min'),
                InfoRow(
                  'Checks cumplidos',
                  '${lastVisit.checks.length} de '
                      '${PointOfSaleCheck.values.length}',
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startVisit,
            icon: const Icon(Icons.storefront),
            label: const Text('Iniciar visita'),
          ),
        ],
      ),
    );
  }
}
