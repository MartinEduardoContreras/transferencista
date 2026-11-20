import 'package:transferencista/models/geo_point.dart';
import 'package:transferencista/services/location_service.dart';

/// Doble de pruebas: siempre devuelve el mismo resultado de ubicación
/// y emite las posiciones indicadas en el seguimiento.
class FakeLocationService implements LocationService {
  const FakeLocationService(this.result, {this.positions = const []});

  final LocationResult result;
  final List<GeoPoint> positions;

  @override
  Future<LocationResult> currentPosition() async => result;

  @override
  Stream<GeoPoint> watchPositions() => Stream.fromIterable(positions);
}
