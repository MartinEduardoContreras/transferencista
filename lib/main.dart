import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_repository.dart';
import 'data/sqflite_store.dart';
import 'services/geolocator_location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SqfliteStore.open();
  final repository = await AppRepository.open(store);
  runApp(
    TransferencistaApp(
      repository: repository,
      locationService: const GeolocatorLocationService(),
    ),
  );
}
