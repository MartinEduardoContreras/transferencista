import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/visit.dart';
import '../utils/format.dart';
import 'visit_detail_screen.dart';
import '../widgets/brand_app_bar.dart';

/// Historial de visitas con indicadores, agrupado por fecha (se puede expandir o colapsar).
class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key, required this.repository});

  final AppRepository repository;

  void _openVisit(BuildContext context, Visit visit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitDetailScreen(repository: repository, visit: visit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final visits = repository.visits;
        final pharmaciesVisited = visits.map((v) => v.pharmacyId).toSet().length;
        final totalMinutes =
            visits.fold<int>(0, (sum, v) => sum + v.duration.inMinutes);
        final avgMinutes = visits.isEmpty ? 0 : totalMinutes ~/ visits.length;
        final totalProducts =
            visits.fold<int>(0, (sum, v) => sum + v.products.length);
        final avgProducts = visits.isEmpty ? 0.0 : totalProducts / visits.length;

        // Agrupa por día; visits ya viene de la más reciente a la más antigua.
        final byDay = <DateTime, List<Visit>>{};
        for (final visit in visits) {
          byDay.putIfAbsent(startOfDay(visit.arrival), () => []).add(visit);
        }
        final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

        return Scaffold(
          appBar: const BrandAppBar(title: 'Visitas'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(label: 'Visitas', value: '${visits.length}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Farmacias visitadas',
                      value: '$pharmaciesVisited',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'Duración promedio',
                      value: '$avgMinutes min',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Productos por visita',
                      value: avgProducts.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (visits.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no hay visitas registradas. Inicia una desde Hoy.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final day in days)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: ValueKey(day),
                    initiallyExpanded: true,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(formatDate(day)),
                    subtitle: Text(
                      '${byDay[day]!.length} '
                      '${byDay[day]!.length == 1 ? 'visita' : 'visitas'}',
                    ),
                    children: [
                      for (final visit in (byDay[day]!
                        ..sort((a, b) => a.arrival.compareTo(b.arrival))))
                        ListTile(
                          title: Text(
                            repository.pharmacyById(visit.pharmacyId)?.name ??
                                'Farmacia',
                          ),
                          subtitle: Text(
                            '${formatTime(visit.arrival)} – '
                            '${formatTime(visit.departure)} · '
                            '${visit.duration.inMinutes} min',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openVisit(context, visit),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
