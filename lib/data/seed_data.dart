import '../models/geo_point.dart';
import '../models/pharmacy.dart';
import '../models/product_record.dart';
import '../models/visit.dart';

/// Datos de ejemplo tomados del documento de proceso. Son ficticios y sirven
/// solo para probar el flujo; se reemplazarán por datos reales del laboratorio.
const seedPortfolio = <String>[
  'Sertralina',
  'K-Llosil',
  'Melatonina',
  'Omega 3',
  'Vitaminas',
];

const seedPharmacies = <Pharmacy>[
  Pharmacy(
    id: 'ph-001',
    name: 'Farmacia San José',
    chain: 'Independiente',
    zone: 'Zona Norte Bogotá',
    priority: 1,
    daysSinceLastPurchase: 43,
  ),
  Pharmacy(
    id: 'ph-002',
    name: 'Drogas La Rebaja Calle 80',
    chain: 'Drogas La Rebaja',
    zone: 'Zona Norte Bogotá',
    priority: 2,
    daysSinceLastPurchase: 12,
  ),
  Pharmacy(
    id: 'ph-003',
    name: 'Cruz Verde Usaquén',
    chain: 'Cruz Verde',
    zone: 'Zona Norte Bogotá',
    priority: 3,
    daysSinceLastPurchase: 5,
  ),
  Pharmacy(
    id: 'ph-004',
    name: 'Farmatodo Chapinero',
    chain: 'Farmatodo',
    zone: 'Zona Norte Bogotá',
    priority: 4,
    daysSinceLastPurchase: 27,
  ),
];

/// Plan de ejemplo para hoy, con las cuatro farmacias en orden de visita.
Map<DateTime, List<String>> buildSeedPlans(DateTime now) => {
      DateTime(now.year, now.month, now.day): const [
        'ph-001',
        'ph-002',
        'ph-003',
        'ph-004',
      ],
    };

/// Visitas de ejemplo en días anteriores, para que la pantalla de visitas
/// tenga datos. Se generan respecto a [now] para no marcar la ruta de hoy.
List<Visit> buildSeedVisits(DateTime now) {
  DateTime at(int daysAgo, int hour, int minute) =>
      DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

  GeoPoint gps(double lat, double lng) =>
      GeoPoint(latitude: lat, longitude: lng, accuracyMeters: 9);

  return [
    Visit(
      id: 'v-seed-001',
      pharmacyId: 'ph-001',
      arrival: at(2, 9, 15),
      departure: at(2, 10, 5),
      products: const [
        ProductRecord(
          product: 'Sertralina',
          displayed: true,
          priceVisible: true,
          units: 2,
        ),
        ProductRecord(
          product: 'Vitaminas',
          displayed: true,
          units: 6,
          competitionPresent: true,
        ),
      ],
      competitors: 'Competencia con promoción 2x1 en vitaminas',
      notes: 'Pidió reposición de Sertralina para la próxima semana.',
      checkIn: gps(4.7110, -74.0721),
      checkOut: gps(4.7111, -74.0722),
    ),
    Visit(
      id: 'v-seed-002',
      pharmacyId: 'ph-002',
      arrival: at(3, 14, 0),
      departure: at(3, 15, 20),
      products: const [
        ProductRecord(
          product: 'Melatonina',
          displayed: true,
          units: 10,
          popPresent: true,
        ),
        ProductRecord(
          product: 'Omega 3',
          displayed: true,
          outOfStock: true,
        ),
      ],
      competitors: '',
      notes: 'Se dejó material POP en exhibidor de caja.',
      checkIn: gps(4.6990, -74.0580),
      checkOut: gps(4.6991, -74.0581),
    ),
    Visit(
      id: 'v-seed-003',
      pharmacyId: 'ph-003',
      arrival: at(5, 10, 30),
      departure: at(5, 11, 10),
      products: const [
        ProductRecord(
          product: 'Vitaminas',
          productVisible: true,
          units: 14,
        ),
        ProductRecord(
          product: 'Sertralina',
          units: 4,
        ),
      ],
      competitors: 'Marca X con exhibidor nuevo',
      notes: '',
      checkIn: gps(4.7040, -74.0320),
      checkOut: gps(4.7041, -74.0321),
    ),
  ];
}
