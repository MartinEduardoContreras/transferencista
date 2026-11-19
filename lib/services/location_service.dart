import '../models/geo_point.dart';

/// Motivos por los que no se pudo obtener la ubicación.
enum LocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

/// Resultado de pedir la ubicación: una coordenada o un motivo de fallo.
class LocationResult {
  const LocationResult.success(GeoPoint this.point) : failure = null;
  const LocationResult.failure(LocationFailure this.failure) : point = null;

  final GeoPoint? point;
  final LocationFailure? failure;

  bool get isSuccess => point != null;
}

/// Abstracción del GPS. La implementación real usa el paquete de geolocalización;
/// en pruebas se usa un doble que devuelve resultados fijos.
abstract class LocationService {
  Future<LocationResult> currentPosition();
}

/// Mensaje en español para mostrar al usuario según el fallo.
String locationFailureMessage(LocationFailure failure) {
  switch (failure) {
    case LocationFailure.servicesDisabled:
      return 'Activa el GPS del teléfono para registrar la ubicación.';
    case LocationFailure.permissionDenied:
      return 'Necesitamos permiso de ubicación para el check-in.';
    case LocationFailure.permissionDeniedForever:
      return 'El permiso de ubicación está bloqueado. Actívalo en los ajustes del teléfono.';
    case LocationFailure.unavailable:
      return 'No pudimos obtener tu ubicación. Intenta de nuevo en un lugar con mejor señal.';
  }
}
