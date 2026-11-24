import 'package:material_ui/material_ui.dart';

import '../models/pharmacy.dart';
import '../models/visit.dart';
import 'local_store.dart';
import 'seed_data.dart';

/// Inicio del día (00:00 local) para usarlo como clave de fecha.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Repositorio de la app. Mantiene los datos en memoria para la interfaz y los
/// guarda en el [LocalStore] (SQLite en el teléfono) en cada cambio.
class AppRepository extends ChangeNotifier {
  AppRepository({
    required List<Pharmacy> pharmacies,
    required this.portfolio,
    List<Visit> visits = const [],
    Map<DateTime, List<String>> plans = const {},
    LocalStore? store,
  })  : _pharmacies = List.of(pharmacies),
        _visits = List.of(visits),
        _plans = {
          for (final entry in plans.entries)
            startOfDay(entry.key): List.of(entry.value),
        },
        _store = store ?? MemoryStore();

  /// Abre el repositorio desde el almacenamiento local. La primera vez carga los
  /// datos de ejemplo y los guarda; después solo lee lo que ya existe.
  static Future<AppRepository> open(LocalStore store, {DateTime? now}) async {
    final snapshot = await store.loadSnapshot();
    if (snapshot.seeded) {
      return AppRepository(
        pharmacies: snapshot.pharmacies,
        portfolio: seedPortfolio,
        visits: snapshot.visits,
        plans: snapshot.plans,
        store: store,
      );
    }

    final clock = now ?? DateTime.now();
    final repo = AppRepository(
      pharmacies: seedPharmacies,
      portfolio: seedPortfolio,
      visits: buildSeedVisits(clock),
      plans: buildSeedPlans(clock),
      store: store,
    );
    for (final pharmacy in repo._pharmacies) {
      await store.savePharmacy(pharmacy);
    }
    for (final entry in repo._plans.entries) {
      await store.savePlan(entry.key, entry.value);
    }
    for (final visit in repo._visits) {
      await store.saveVisit(visit);
    }
    await store.markSeeded();
    return repo;
  }

  /// Repositorio solo en memoria, con datos de ejemplo. Usado en pruebas.
  factory AppRepository.seeded({DateTime? now}) {
    final clock = now ?? DateTime.now();
    return AppRepository(
      pharmacies: seedPharmacies,
      portfolio: seedPortfolio,
      visits: buildSeedVisits(clock),
      plans: buildSeedPlans(clock),
    );
  }

  final List<Pharmacy> _pharmacies;
  final List<Visit> _visits;
  final LocalStore _store;

  /// Plan de visitas por día: lista de ids de farmacia en orden de visita.
  final Map<DateTime, List<String>> _plans;

  /// Productos del laboratorio que se revisan en inventario y activación.
  final List<String> portfolio;

  /// Todas las farmacias, ordenadas por nombre.
  List<Pharmacy> get pharmacies {
    final sorted = List.of(_pharmacies)..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(sorted);
  }

  /// Todas las farmacias por prioridad (1 = más alta).
  List<Pharmacy> get route {
    final sorted = List.of(_pharmacies)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted;
  }

  /// Todas las visitas, de la más reciente a la más antigua.
  List<Visit> get visits {
    final sorted = List.of(_visits)
      ..sort((a, b) => b.arrival.compareTo(a.arrival));
    return List.unmodifiable(sorted);
  }

  /// Ids de farmacias planeadas para [day], en orden de visita.
  List<String> planIds(DateTime day) =>
      List.unmodifiable(_plans[startOfDay(day)] ?? const <String>[]);

  /// Farmacias planeadas para [day], en orden de visita.
  List<Pharmacy> planFor(DateTime day) {
    final result = <Pharmacy>[];
    for (final id in planIds(day)) {
      final pharmacy = pharmacyById(id);
      if (pharmacy != null) result.add(pharmacy);
    }
    return result;
  }

  /// Reemplaza el plan de [day] con los ids dados, en ese orden.
  Future<void> setPlan(DateTime day, List<String> pharmacyIds) async {
    final key = startOfDay(day);
    if (pharmacyIds.isEmpty) {
      _plans.remove(key);
    } else {
      _plans[key] = List.of(pharmacyIds);
    }
    notifyListeners();
    await _store.savePlan(key, pharmacyIds);
  }

  Pharmacy? pharmacyById(String id) {
    final matches = _pharmacies.where((p) => p.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  bool wasVisitedToday(Pharmacy pharmacy) {
    final now = DateTime.now();
    return _visits.any(
      (v) => v.pharmacyId == pharmacy.id && _isSameDay(v.arrival, now),
    );
  }

  Visit? lastVisit(Pharmacy pharmacy) {
    final visits = _visits.where((v) => v.pharmacyId == pharmacy.id).toList()
      ..sort((a, b) => b.arrival.compareTo(a.arrival));
    return visits.isEmpty ? null : visits.first;
  }

  String newPharmacyId() => 'ph-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> addPharmacy(Pharmacy pharmacy) async {
    _pharmacies.add(pharmacy);
    notifyListeners();
    await _store.savePharmacy(pharmacy);
  }

  Future<void> saveVisit(Visit visit) async {
    _visits.add(visit);
    notifyListeners();
    await _store.saveVisit(visit);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
