import 'package:material_ui/material_ui.dart';

import 'data/app_repository.dart';
import 'screens/home_screen.dart';

class TransferencistaApp extends StatelessWidget {
  const TransferencistaApp({super.key, required this.repository});

  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transferencista',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(repository: repository),
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
