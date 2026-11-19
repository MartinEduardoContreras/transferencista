import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transferencista/app.dart';
import 'package:transferencista/data/app_repository.dart';
import 'package:transferencista/models/geo_point.dart';
import 'package:transferencista/models/visit.dart';
import 'package:transferencista/screens/visit_screen.dart';
import 'package:transferencista/services/location_service.dart';
import 'package:transferencista/utils/format.dart';

import 'fakes/fake_location_service.dart';

const _point = GeoPoint(latitude: 4.6, longitude: -74.1, accuracyMeters: 12);

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
      checkIn: _point,
      checkOut: _point,
    ));

    expect(repo.wasVisitedToday(pharmacy), isTrue);
    expect(repo.lastVisit(pharmacy)?.inventory['Sertralina'], 3);
    expect(repo.lastVisit(pharmacy)?.checkIn?.accuracyMeters, 12);
  });

  test('formato de pesos colombianos', () {
    expect(formatCop(185000), '\$185.000');
    expect(formatCop(950), '\$950');
  });

  testWidgets('la app muestra la ruta del día', (tester) async {
    await tester.pumpWidget(
      TransferencistaApp(
        repository: AppRepository.seeded(),
        locationService: const FakeLocationService(
          LocationResult.failure(LocationFailure.unavailable),
        ),
      ),
    );
    expect(find.text('Ruta del día'), findsOneWidget);
    expect(find.text('Farmacia San José'), findsOneWidget);
  });

  testWidgets('check-in con GPS muestra la ubicación registrada',
      (tester) async {
    final repo = AppRepository.seeded();
    await tester.pumpWidget(MaterialApp(
      home: VisitScreen(
        repository: repo,
        pharmacy: repo.route.first,
        locationService: const FakeLocationService(
          LocationResult.success(_point),
        ),
      ),
    ));

    await tester.tap(find.text('Registrar llegada'));
    await tester.pumpAndSettle();

    expect(find.text('Llegada registrada'), findsOneWidget);
    expect(find.textContaining('(±12 m)'), findsOneWidget);
  });

  testWidgets('sin GPS muestra el motivo del fallo', (tester) async {
    final repo = AppRepository.seeded();
    await tester.pumpWidget(MaterialApp(
      home: VisitScreen(
        repository: repo,
        pharmacy: repo.route.first,
        locationService: const FakeLocationService(
          LocationResult.failure(LocationFailure.servicesDisabled),
        ),
      ),
    ));

    await tester.tap(find.text('Registrar llegada'));
    await tester.pumpAndSettle();

    expect(
      find.text(locationFailureMessage(LocationFailure.servicesDisabled)),
      findsOneWidget,
    );
    expect(find.text('Llegada registrada'), findsNothing);
  });
}
