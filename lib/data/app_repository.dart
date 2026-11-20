import 'package:material_ui/material_ui.dart';

import '../models/pharmacy.dart';
import '../models/visit.dart';
import 'seed_data.dart';

/// Repositorio en memoria. Notifica a la UI cuando cambian farmacias o visitas.
/// En fases posteriores se reemplazará por base de datos local (offline) y sincronización.
class AppRepository extends ChangeNotifier {
  AppRepository({
    required List<Pharmacy> pharmacies,
    required this.portfolio,
    List<Visit> visits = const [],
  })  : _pharmacies = List.of(pharmacies),
        _visits = List.of(visits);

  factory AppRepository.seeded({DateTime? now}) {
    final clock = now ?? DateTime.now();
    return AppRepository(
      pharmacies: seedPharmacies,
      portfolio: seedPortfolio,
      visits: buildSeedVisits(clock),
    );
  }

  final List<Pharmacy> _pharmacies;
  final List<Visit> _visits;

  /// Productos del laboratorio que se revisan en inventario y activación.
  final List<String> portfolio;

  /// Todas las farmacias, ordenadas por nombre.
  List<Pharmacy> get pharmacies {
    final sorted = List.of(_pharmacies)..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(sorted);
  }

  /// Ruta del día ordenada por prioridad.
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
