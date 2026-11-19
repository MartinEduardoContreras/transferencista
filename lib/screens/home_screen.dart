import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../services/location_service.dart';
import 'pharmacy_detail_screen.dart';

/// Ruta del día: lista de farmacias priorizadas y cobertura de la jornada.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.locationService,
  });

  final AppRepository repository;
  final LocationService locationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _coverageGoal = 0.95;

  Future<void> _openPharmacy(Pharmacy pharmacy) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PharmacyDetailScreen(
          repository: widget.repository,
          pharmacy: pharmacy,
          locationService: widget.locationService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    final route = repo.route;
    final visited = route.where(repo.wasVisitedToday).length;
    final coverage = route.isEmpty ? 0.0 : visited / route.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Ruta del día')),
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
          for (final pharmacy in route)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${pharmacy.priority}')),
                title: Text(pharmacy.name),
                subtitle: Text('${pharmacy.chain} · ${pharmacy.zone}'),
                trailing: repo.wasVisitedToday(pharmacy)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),
                onTap: () => _openPharmacy(pharmacy),
              ),
            ),
        ],
      ),
    );
  }
}
