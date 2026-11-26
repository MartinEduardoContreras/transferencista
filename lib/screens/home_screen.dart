import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../services/location_service.dart';
import '../utils/format.dart';
import 'pharmacy_detail_screen.dart';

/// Planeación del día: las farmacias del plan de hoy, en orden de visita, y la cobertura.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.locationService,
  });

  final AppRepository repository;
  final LocationService locationService;

  static const _coverageGoal = 0.95;

  void _openPharmacy(BuildContext context, Pharmacy pharmacy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PharmacyDetailScreen(
          repository: repository,
          pharmacy: pharmacy,
          locationService: locationService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final today = DateTime.now();
        final planned = repository.planFor(today);
        final visited = planned.where(repository.wasVisitedToday).length;
        final coverage = planned.isEmpty ? 0.0 : visited / planned.length;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Planeación del día'),
                      Text(
                        formatDate(today),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cobertura de hoy',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: coverage),
                      const SizedBox(height: 8),
                      Text(
                        '$visited de ${planned.length} farmacias visitadas '
                        '(meta ${(_coverageGoal * 100).round()}%)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (planned.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay plan para hoy. Créalo en la pestaña Plan.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (var i = 0; i < planned.length; i++)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(planned[i].name),
                    subtitle: Text(
                      '${planned[i].chain} · ${planned[i].lastPurchaseLabel}',
                    ),
                    trailing: repository.wasVisitedToday(planned[i])
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _openPharmacy(context, planned[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
