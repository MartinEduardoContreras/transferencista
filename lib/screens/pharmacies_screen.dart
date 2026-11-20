import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../models/pharmacy.dart';
import '../services/location_service.dart';
import 'new_pharmacy_screen.dart';
import 'pharmacy_detail_screen.dart';

/// Listado de farmacias con acceso a la creación de nuevas.
class PharmaciesScreen extends StatelessWidget {
  const PharmaciesScreen({
    super.key,
    required this.repository,
    required this.locationService,
  });

  final AppRepository repository;
  final LocationService locationService;

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

  Future<void> _createPharmacy(BuildContext context) async {
    final created = await Navigator.of(context).push<Pharmacy>(
      MaterialPageRoute(
        builder: (_) => NewPharmacyScreen(repository: repository),
      ),
    );
    if (created != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Farmacia "${created.name}" creada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final pharmacies = repository.pharmacies;
        return Scaffold(
          appBar: AppBar(title: const Text('Farmacias')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createPharmacy(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva farmacia'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final pharmacy in pharmacies)
                Card(
                  child: ListTile(
                    title: Text(pharmacy.name),
                    subtitle: Text(
                      '${pharmacy.chain} · ${pharmacy.zone}\n'
                      '${pharmacy.lastPurchaseLabel}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
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
