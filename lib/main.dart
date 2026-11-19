import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_repository.dart';
import 'services/geolocator_location_service.dart';

void main() {
  runApp(
    TransferencistaApp(
      repository: AppRepository.seeded(),
      locationService: const GeolocatorLocationService(),
    ),
  );
}
