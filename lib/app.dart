import 'package:material_ui/material_ui.dart';

import 'data/app_repository.dart';
import 'screens/app_shell.dart';
import 'services/location_service.dart';

class TransferencistaApp extends StatelessWidget {
  const TransferencistaApp({
    super.key,
    required this.repository,
    required this.locationService,
  });

  final AppRepository repository;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transferencista',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AppShell(repository: repository, locationService: locationService),
    );
  }
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C7B)),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
