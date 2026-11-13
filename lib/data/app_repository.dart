import '../models/pharmacy.dart';
import '../models/visit.dart';
import 'seed_data.dart';

/// Repositorio en memoria. En fases posteriores se reemplazará por
/// una implementación con base de datos local (offline) y sincronización.
class AppRepository {
  AppRepository({
    required List<Pharmacy> pharmacies,
    required this.portfolio,
  }) : _pharmacies = List.of(pharmacies);

  factory AppRepository.seeded() => AppRepository(
        pharmacies: seedPharmacies,
        portfolio: seedPortfolio,
      );

  final List<Pharmacy> _pharmacies;
  final List<Visit> _visits = [];

  /// Productos del laboratorio que se revisan en inventario y activación.
  final List<String> portfolio;

  /// Ruta del día ordenada por prioridad.
  List<Pharmacy> get route {
    final sorted = List.of(_pharmacies)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted;
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

  void saveVisit(Visit visit) => _visits.add(visit);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
