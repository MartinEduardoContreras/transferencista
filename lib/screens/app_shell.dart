import 'package:material_ui/material_ui.dart';

import '../data/app_repository.dart';
import '../services/location_service.dart';
import 'home_screen.dart';
import 'pharmacies_screen.dart';
import 'visits_screen.dart';

/// Contenedor principal con la navegación inferior: Hoy, Visitas y Farmacias.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.locationService,
  });

  final AppRepository repository;
  final LocationService locationService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            repository: widget.repository,
            locationService: widget.locationService,
          ),
          VisitsScreen(repository: widget.repository),
          PharmaciesScreen(
            repository: widget.repository,
            locationService: widget.locationService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Visitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Farmacias',
          ),
        ],
      ),
    );
  }
}
