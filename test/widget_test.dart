import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transferencista/app.dart';
import 'package:transferencista/data/app_repository.dart';
import 'package:transferencista/data/distributors.dart';
import 'package:transferencista/data/local_store.dart';
import 'package:transferencista/data/product_catalog.dart';
import 'package:transferencista/models/geo_point.dart';
import 'package:transferencista/models/pharmacy.dart';
import 'package:transferencista/models/product_record.dart';
import 'package:transferencista/models/transfer.dart';
import 'package:transferencista/models/visit.dart';
import 'package:transferencista/screens/new_pharmacy_screen.dart';
import 'package:transferencista/screens/transfer_screen.dart';
import 'package:transferencista/screens/visit_screen.dart';
import 'package:transferencista/services/location_service.dart';
import 'package:transferencista/services/movement_tracker.dart';
import 'package:transferencista/utils/geo.dart';
import 'package:transferencista/utils/format.dart';

import 'fakes/fake_location_service.dart';

const _point = GeoPoint(latitude: 4.6, longitude: -74.1, accuracyMeters: 12);

/// Farmacias de prueba (ficticias).
const _alfa = Pharmacy(
  id: 'ph-001',
  name: 'Farmacia Alfa',
  chain: 'Independiente',
  zone: 'Zona Norte',
  priority: 1,
);
const _beta = Pharmacy(
  id: 'ph-002',
  name: 'Farmacia Beta',
  chain: 'Independiente',
  zone: 'Zona Sur',
  priority: 2,
);

AppRepository _repoWithPharmacies({Map<DateTime, List<String>> plans = const {}}) =>
    AppRepository(pharmacies: const [_beta, _alfa], plans: plans);

void main() {
  test('la ruta se ordena por prioridad', () {
    final repo = _repoWithPharmacies();
    final priorities = repo.route.map((p) => p.priority).toList();
    expect(priorities, [1, 2]);
  });

  test('el catálogo viene de productos.xlsx sin el texto posterior a INVIMA', () {
    expect(productCatalog, hasLength(44));
    expect(productCatalog.any((p) => p.contains('INVIMA')), isFalse);
    expect(productCatalog, contains('LYPTUS JBE NIÑOS'));
    expect(distributors, hasLength(25));
  });

  test('guardar una visita marca la farmacia como visitada hoy', () async {
    final repo = _repoWithPharmacies();
    final pharmacy = repo.route.first;
    expect(repo.wasVisitedToday(pharmacy), isFalse);

    final now = DateTime.now();
    await repo.saveVisit(Visit(
      id: '1',
      pharmacyId: pharmacy.id,
      arrival: now,
      departure: now,
      products: const [
        ProductRecord(product: 'LYPTUS JBE ADULTOS', displayed: true, units: 3),
      ],
      checkIn: _point,
      checkOut: _point,
    ));

    expect(repo.wasVisitedToday(pharmacy), isTrue);
    final history = repo.lastProductRecord(pharmacy, 'LYPTUS JBE ADULTOS');
    expect(history?.record.units, 3);
    expect(history?.record.displayed, isTrue);
    expect(repo.lastVisit(pharmacy)?.checkIn?.accuracyMeters, 12);
  });

  test('el historial por producto devuelve el último registro', () async {
    final repo = _repoWithPharmacies();
    final older = DateTime.now().subtract(const Duration(days: 5));
    final newer = DateTime.now().subtract(const Duration(days: 1));
    await repo.saveVisit(Visit(
      id: 'old',
      pharmacyId: _alfa.id,
      arrival: older,
      departure: older,
      products: const [ProductRecord(product: 'CALCIMAX X 500 GR', units: 14)],
    ));
    await repo.saveVisit(Visit(
      id: 'new',
      pharmacyId: _alfa.id,
      arrival: newer,
      departure: newer,
      products: const [ProductRecord(product: 'CALCIMAX X 500 GR', units: 2)],
    ));

    expect(repo.lastProductRecord(_alfa, 'CALCIMAX X 500 GR')?.record.units, 2);
    expect(repo.lastProductRecord(_alfa, 'FIBLAX TARRO X 400 GR'), isNull);
  });

  test('formato de pesos colombianos', () {
    expect(formatCop(185000), '\$185.000');
    expect(formatCop(950), '\$950');
  });

  test('el plan del día conserva el orden de visita y se puede cambiar', () async {
    final today = DateTime.now();
    final repo = _repoWithPharmacies(plans: {today: ['ph-001', 'ph-002']});
    expect(repo.planIds(today), ['ph-001', 'ph-002']);

    await repo.setPlan(today, ['ph-002', 'ph-001']);
    expect(repo.planFor(today).map((p) => p.id), ['ph-002', 'ph-001']);

    final tomorrow = today.add(const Duration(days: 1));
    expect(repo.planFor(tomorrow), isEmpty);
  });

  test('una transferencia guardada queda en la visita', () async {
    final repo = _repoWithPharmacies();
    final now = DateTime.now();
    await repo.saveVisit(Visit(
      id: 'tr',
      pharmacyId: _alfa.id,
      arrival: now,
      departure: now,
      transfers: const [
        Transfer(
          product: 'FOX SURE FRESA X 400 GR',
          distributor: 'MARIO TOBON',
          quantity: 6,
        ),
        Transfer(
          product: 'FOX SURE VAINILLA X 400 GRAMOS',
          distributor: 'MARIO TOBON',
          quantity: 2,
        ),
      ],
    ));

    final saved = repo.lastVisit(_alfa)!;
    expect(saved.transfers, hasLength(2));
    expect(saved.transfers.first.quantity, 6);
  });

  test('el responsable y la ruta de la firma quedan en la visita', () async {
    final repo = _repoWithPharmacies();
    final now = DateTime.now();
    await repo.saveVisit(Visit(
      id: 'firma',
      pharmacyId: _alfa.id,
      arrival: now,
      departure: now,
      signerName: 'Ana Pérez',
      signaturePath: '/docs/firmas/1_firma.png',
    ));

    final saved = repo.lastVisit(_alfa)!;
    expect(saved.signerName, 'Ana Pérez');
    expect(saved.signaturePath, '/docs/firmas/1_firma.png');
  });

  testWidgets('antes del check-in solo se ofrece registrar la llegada',
      (tester) async {
    final repo = _repoWithPharmacies();
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
    expect(find.text('Productos en esta visita'), findsNothing);
    expect(find.text('Finalizar visita'), findsNothing);

    await tester.tap(find.text('Registrar llegada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acepto'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Productos en esta visita'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Productos en esta visita'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Finalizar visita'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Finalizar visita'), findsOneWidget);
  });

  testWidgets('la transferencia exige producto, distribuidor y cantidad',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TransferScreen(
        catalog: productCatalog,
        distributors: distributors,
      ),
    ));

    await tester.dragUntilVisible(
      find.text('Guardar transferencia'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Guardar transferencia'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona el producto'), findsOneWidget);
    expect(find.text('Selecciona el distribuidor'), findsOneWidget);
    expect(find.text('Escribe una cantidad mayor a 0'), findsOneWidget);
  });

  test('la distancia entre dos puntos es correcta', () {
    const a = GeoPoint(latitude: 4.7, longitude: -74.07, accuracyMeters: 5);
    // 0,01 grados de latitud son aproximadamente 1.112 m.
    const b = GeoPoint(latitude: 4.71, longitude: -74.07, accuracyMeters: 5);
    expect(distanceMeters(a, b), closeTo(1112, 5));
  });

  test('el trayecto avisa al salir del radio y registra cada 10 minutos', () {
    const site = GeoPoint(latitude: 4.7, longitude: -74.07, accuracyMeters: 5);
    // ~111 m por cada 0,001 grados de latitud.
    const near = GeoPoint(latitude: 4.7001, longitude: -74.07, accuracyMeters: 5);
    const far = GeoPoint(latitude: 4.706, longitude: -74.07, accuracyMeters: 5); // ~670 m
    final t0 = DateTime(2026, 11, 19, 9);
    final tracker = MovementTracker(site: site);

    expect(tracker.onPosition(near, t0), TrackEvent.none);
    expect(tracker.onPosition(far, t0), TrackEvent.leftRadius);
    expect(tracker.points, hasLength(1));

    // Sigue fuera antes de 10 minutos: no registra ni avisa de nuevo.
    expect(tracker.onPosition(far, t0.add(const Duration(minutes: 5))), TrackEvent.none);
    expect(tracker.points, hasLength(1));

    // A los 10 minutos registra otro punto.
    expect(
      tracker.onPosition(far, t0.add(const Duration(minutes: 10))),
      TrackEvent.logged,
    );
    expect(tracker.points, hasLength(2));

    // Vuelve al radio: no registra más puntos.
    expect(tracker.onPosition(near, t0.add(const Duration(minutes: 20))), TrackEvent.none);
    expect(tracker.points, hasLength(2));
  });

  test('open arranca sin datos de prueba y después lee lo ya guardado', () async {
    final store = MemoryStore();
    final first = await AppRepository.open(store);
    expect(first.pharmacies, isEmpty);
    expect(first.visits, isEmpty);

    await first.addPharmacy(const Pharmacy(
      id: 'ph-persistida',
      name: 'Farmacia Persistida',
      chain: 'Otra',
      zone: 'Zona Sur',
      priority: 1,
    ));
    await first.setPlan(DateTime(2026, 11, 21), ['ph-persistida']);
    await first.saveVisit(Visit(
      id: 'v-persistida',
      pharmacyId: 'ph-persistida',
      arrival: DateTime(2026, 11, 21, 9),
      departure: DateTime(2026, 11, 21, 9, 30),
      transfers: const [
        Transfer(
          product: 'VIT COMPLEX FRESA X 400 GR',
          distributor: 'DROGUERIA VITALIS MEDICA',
          quantity: 4,
        ),
      ],
    ));

    final second = await AppRepository.open(store);
    expect(second.pharmacies.length, 1);
    expect(second.pharmacyById('ph-persistida')?.name, 'Farmacia Persistida');
    expect(second.planIds(DateTime(2026, 11, 21)), ['ph-persistida']);
    expect(second.visits.single.transfers.single.quantity, 4);
  });

  test('addPharmacy agrega la farmacia a la ruta y notifica', () {
    final repo = _repoWithPharmacies();
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
    final repo = _repoWithPharmacies(plans: {DateTime.now(): ['ph-001']});
    await tester.pumpWidget(
      TransferencistaApp(
        repository: repo,
        locationService: const FakeLocationService(
          LocationResult.failure(LocationFailure.unavailable),
        ),
      ),
    );
    expect(find.text('Planeación del día'), findsOneWidget);
    expect(find.text('Farmacia Alfa'), findsOneWidget);
  });

  testWidgets('el formulario de farmacia valida los campos obligatorios',
      (tester) async {
    final repo = _repoWithPharmacies();
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

  testWidgets('la pestaña Visitas muestra el historial', (tester) async {
    final repo = _repoWithPharmacies();
    final now = DateTime.now();
    await repo.saveVisit(Visit(
      id: 'h1',
      pharmacyId: _alfa.id,
      arrival: now,
      departure: now.add(const Duration(minutes: 30)),
    ));
    await tester.pumpWidget(
      TransferencistaApp(
        repository: repo,
        locationService: const FakeLocationService(
          LocationResult.failure(LocationFailure.unavailable),
        ),
      ),
    );
    await tester.tap(find.text('Visitas'));
    await tester.pumpAndSettle();

    expect(find.text('Farmacia Alfa'), findsOneWidget);
    expect(find.text('Duración promedio'), findsOneWidget);
  });

  testWidgets('check-in con GPS muestra la ubicación registrada',
      (tester) async {
    final repo = _repoWithPharmacies();
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
    final repo = _repoWithPharmacies();
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
