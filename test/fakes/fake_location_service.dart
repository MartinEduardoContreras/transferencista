import 'package:transferencista/services/location_service.dart';

/// Doble de pruebas: siempre devuelve el mismo resultado de ubicación.
class FakeLocationService implements LocationService {
  const FakeLocationService(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> currentPosition() async => result;
}
