import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../services/location_service.dart';
import '../utils/format.dart';
import 'pharmacy_detail_screen.dart';

/// Planeación del día: farmacias priorizadas, estado de cada una y cobertura.
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
        final route = repository.route;
        final visited = route.where(repository.wasVisitedToday).length;
        final coverage = route.isEmpty ? 0.0 : visited / route.length;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Planeación del día'),
                Text(
                  formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
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
                        '$visited de ${route.length} farmacias visitadas '
                        '(meta ${(_coverageGoal * 100).round()}%)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (route.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay farmacias en la ruta. Crea una en la pestaña Farmacias.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final pharmacy in route)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${pharmacy.priority}')),
                    title: Text(pharmacy.name),
                    subtitle: Text(
                      '${pharmacy.chain} · ${pharmacy.lastPurchaseLabel}',
                    ),
                    trailing: repository.wasVisitedToday(pharmacy)
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _openPharmacy(context, pharmacy),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
