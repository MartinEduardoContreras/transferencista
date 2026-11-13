import 'package:flutter_test/flutter_test.dart';
import 'package:transferencista/app.dart';
import 'package:transferencista/data/app_repository.dart';
import 'package:transferencista/models/visit.dart';
import 'package:transferencista/utils/format.dart';

void main() {
  test('la ruta se ordena por prioridad', () {
    final repo = AppRepository.seeded();
    final priorities = repo.route.map((p) => p.priority).toList();
    expect(priorities, [...priorities]..sort());
  });

  test('guardar una visita marca la farmacia como visitada hoy', () {
    final repo = AppRepository.seeded();
    final pharmacy = repo.route.first;
    expect(repo.wasVisitedToday(pharmacy), isFalse);

    final now = DateTime.now();
    repo.saveVisit(Visit(
      id: '1',
      pharmacyId: pharmacy.id,
      arrival: now,
      departure: now,
      checks: {PointOfSaleCheck.productDisplayed},
      inventory: const {'Sertralina': 3},
    ));

    expect(repo.wasVisitedToday(pharmacy), isTrue);
    expect(repo.lastVisit(pharmacy)?.inventory['Sertralina'], 3);
  });

  test('formato de pesos colombianos', () {
    expect(formatCop(185000), '\$185.000');
    expect(formatCop(950), '\$950');
  });

  testWidgets('la app muestra la ruta del día', (tester) async {
    await tester.pumpWidget(
      TransferencistaApp(repository: AppRepository.seeded()),
    );
    expect(find.text('Ruta del día'), findsOneWidget);
    expect(find.text('Farmacia San José'), findsOneWidget);
  });
}
