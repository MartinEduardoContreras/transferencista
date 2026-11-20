import 'package:material_ui/material_ui.dart';

import '../models/pharmacy.dart';
import '../models/visit.dart';
import 'seed_data.dart';

/// Inicio del día (00:00 local) para usarlo como clave de fecha.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Repositorio en memoria. Notifica a la UI cuando cambian farmacias, visitas o planes.
/// En fases posteriores se reemplazará por base de datos local (offline) y sincronización.
class AppRepository extends ChangeNotifier {
  AppRepository({
    required List<Pharmacy> pharmacies,
    required this.portfolio,
    List<Visit> visits = const [],
    Map<DateTime, List<String>> plans = const {},
  })  : _pharmacies = List.of(pharmacies),
        _visits = List.of(visits),
        _plans = {
          for (final entry in plans.entries)
            startOfDay(entry.key): List.of(entry.value),
        };

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
  void setPlan(DateTime day, List<String> pharmacyIds) {
    final key = startOfDay(day);
    if (pharmacyIds.isEmpty) {
      _plans.remove(key);
    } else {
      _plans[key] = List.of(pharmacyIds);
    }
    notifyListeners();
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

  void addPharmacy(Pharmacy pharmacy) {
    _pharmacies.add(pharmacy);
    notifyListeners();
  }

  void saveVisit(Visit visit) {
    _visits.add(visit);
    notifyListeners();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
