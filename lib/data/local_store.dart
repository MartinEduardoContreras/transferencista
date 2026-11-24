import '../models/pharmacy.dart';
import '../models/visit.dart';

/// Clave de fecha con formato yyyy-MM-dd (para guardar planes por día).
String dayKey(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Datos leídos del almacenamiento local al iniciar la app.
class StoreSnapshot {
  const StoreSnapshot({
    required this.seeded,
    this.pharmacies = const [],
    this.visits = const [],
    this.plans = const {},
  });

  /// True si los datos de ejemplo ya se cargaron alguna vez.
  final bool seeded;
  final List<Pharmacy> pharmacies;
  final List<Visit> visits;
  final Map<DateTime, List<String>> plans;
}

/// Contrato de almacenamiento local. Hay una implementación con SQLite para la app
/// y una en memoria para pruebas.
abstract class LocalStore {
  Future<StoreSnapshot> loadSnapshot();

  Future<void> savePharmacy(Pharmacy pharmacy);

  /// Reemplaza el plan del día completo, en el orden dado.
  Future<void> savePlan(DateTime day, List<String> pharmacyIds);

  /// Guarda la visita con sus fotos y puntos de trayecto.
  Future<void> saveVisit(Visit visit);

  Future<void> markSeeded();
}

/// Almacenamiento en memoria: no persiste nada entre ejecuciones. Se usa en pruebas.
class MemoryStore implements LocalStore {
  bool _seeded = false;
  final Map<String, Pharmacy> _pharmacies = {};
  final Map<String, Visit> _visits = {};
  final Map<DateTime, List<String>> _plans = {};

  @override
  Future<StoreSnapshot> loadSnapshot() async => StoreSnapshot(
        seeded: _seeded,
        pharmacies: _pharmacies.values.toList(),
        visits: _visits.values.toList(),
        plans: {for (final e in _plans.entries) e.key: List.of(e.value)},
      );

  @override
  Future<void> savePharmacy(Pharmacy pharmacy) async {
    _pharmacies[pharmacy.id] = pharmacy;
  }

  @override
  Future<void> savePlan(DateTime day, List<String> pharmacyIds) async {
    final key = DateTime(day.year, day.month, day.day);
    if (pharmacyIds.isEmpty) {
      _plans.remove(key);
    } else {
      _plans[key] = List.of(pharmacyIds);
    }
  }

  @override
  Future<void> saveVisit(Visit visit) async {
    _visits[visit.id] = visit;
  }

  @override
  Future<void> markSeeded() async {
    _seeded = true;
  }
}
