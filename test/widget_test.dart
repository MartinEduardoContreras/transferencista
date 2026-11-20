import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transferencista/app.dart';
import 'package:transferencista/data/app_repository.dart';
import 'package:transferencista/models/geo_point.dart';
import 'package:transferencista/models/pharmacy.dart';
import 'package:transferencista/models/visit.dart';
import 'package:transferencista/screens/new_pharmacy_screen.dart';
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

  test('las visitas de ejemplo no marcan la ruta de hoy', () {
    final repo = AppRepository.seeded();
    expect(repo.visits, isNotEmpty);
    expect(repo.route.any(repo.wasVisitedToday), isFalse);
  });

  test('el plan del día conserva el orden de visita y se puede cambiar', () {
    final repo = AppRepository.seeded();
    final today = DateTime.now();
    expect(repo.planIds(today), ['ph-001', 'ph-002', 'ph-003', 'ph-004']);

    repo.setPlan(today, ['ph-003', 'ph-001']);
    expect(repo.planFor(today).map((p) => p.id), ['ph-003', 'ph-001']);

    final tomorrow = today.add(const Duration(days: 1));
    expect(repo.planFor(tomorrow), isEmpty);
  });

  testWidgets('antes del check-in solo se ofrece registrar la llegada',
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

    expect(find.text('Registrar llegada'), findsOneWidget);
    expect(find.text('Validación en el punto'), findsNothing);
    expect(find.text('Finalizar visita'), findsNothing);

    await tester.tap(find.text('Registrar llegada'));
    await tester.pumpAndSettle();

    expect(find.text('Validación en el punto'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Finalizar visita'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Finalizar visita'), findsOneWidget);
  });

  test('addPharmacy agrega la farmacia a la ruta y notifica', () {
    final repo = AppRepository.seeded();
    var notified = 0;
    repo.addListener(() => notified++);
    final before = repo.route.length;

    repo.addPharmacy(const Pharmacy(
      id: 'ph-test',
      name: 'Farmacia Nueva',
      chain: 'Otra',
      zone: 'Zona Sur',
      priority: 2,
    ));

    expect(repo.route.length, before + 1);
    expect(repo.pharmacyById('ph-test')?.name, 'Farmacia Nueva');
    expect(notified, 1);
  });

  testWidgets('la app muestra la planeación del día', (tester) async {
    await tester.pumpWidget(
      TransferencistaApp(
        repository: AppRepository.seeded(),
        locationService: const FakeLocationService(
          LocationResult.failure(LocationFailure.unavailable),
        ),
      ),
    );
    expect(find.text('Planeación del día'), findsOneWidget);
    expect(find.text('Farmacia San José'), findsOneWidget);
  });

  testWidgets('el formulario de farmacia valida los campos obligatorios',
      (tester) async {
    final repo = AppRepository.seeded();
    final before = repo.pharmacies.length;
    await tester.pumpWidget(MaterialApp(
      home: NewPharmacyScreen(repository: repo),
    ));

    await tester.dragUntilVisible(
      find.text('Guardar farmacia'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Guardar farmacia'));
    await tester.pumpAndSettle();

    // Volver arriba para ver los mensajes de error de los primeros campos.
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el nombre de la farmacia'), findsOneWidget);
    expect(find.text('Escribe la zona'), findsOneWidget);
    expect(repo.pharmacies.length, before);
  });

  testWidgets('la pestaña Visitas muestra el historial de ejemplo',
      (tester) async {
    await tester.pumpWidget(
      TransferencistaApp(
        repository: AppRepository.seeded(),
        locationService: const FakeLocationService(
          LocationResult.failure(LocationFailure.unavailable),
        ),
      ),
    );
    await tester.tap(find.text('Visitas'));
    await tester.pumpAndSettle();

    expect(find.text('Farmacia San José'), findsOneWidget);
    expect(find.text('Duración promedio'), findsOneWidget);
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
