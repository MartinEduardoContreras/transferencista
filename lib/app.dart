import 'package:material_ui/material_ui.dart';

import 'data/app_repository.dart';
import 'screens/app_shell.dart';
import 'screens/splash_screen.dart';
import 'services/location_service.dart';

class TransferencistaApp extends StatelessWidget {
  const TransferencistaApp({
    super.key,
    required this.repository,
    required this.locationService,
    this.showSplash = true,
  });

  final AppRepository repository;
  final LocationService locationService;

  /// Muestra primero la pantalla de inicio animada. Las pruebas la desactivan.
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    final shell = AppShell(repository: repository, locationService: locationService);
    return MaterialApp(
      title: 'Transferencista',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: showSplash ? _StartGate(child: shell) : shell,
    );
  }
}

/// Muestra la pantalla de inicio y después el contenido de [child].
class _StartGate extends StatefulWidget {
  const _StartGate({required this.child});

  final Widget child;

  @override
  State<_StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<_StartGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return SplashScreen(onFinished: () => setState(() => _done = true));
  }
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C7B)),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
