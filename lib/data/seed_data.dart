import '../models/pharmacy.dart';

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
    averageTicket: 185000,
    topProduct: 'Sertralina',
    newProduct: 'K-Llosil',
    recentProducts: ['Sertralina', 'Vitaminas'],
    estimatedStock: {'Sertralina': 2, 'Vitaminas': 6},
  ),
  Pharmacy(
    id: 'ph-002',
    name: 'Drogas La Rebaja Calle 80',
    chain: 'Drogas La Rebaja',
    zone: 'Zona Norte Bogotá',
    priority: 2,
    daysSinceLastPurchase: 12,
    averageTicket: 420000,
    topProduct: 'Melatonina',
    newProduct: 'Omega 3',
    recentProducts: ['Melatonina', 'Omega 3'],
    estimatedStock: {'Melatonina': 10},
  ),
  Pharmacy(
    id: 'ph-003',
    name: 'Cruz Verde Usaquén',
    chain: 'Cruz Verde',
    zone: 'Zona Norte Bogotá',
    priority: 3,
    daysSinceLastPurchase: 5,
    averageTicket: 360000,
    topProduct: 'Vitaminas',
    recentProducts: ['Vitaminas'],
    estimatedStock: {'Vitaminas': 14, 'Sertralina': 4},
  ),
  Pharmacy(
    id: 'ph-004',
    name: 'Farmatodo Chapinero',
    chain: 'Farmatodo',
    zone: 'Zona Norte Bogotá',
    priority: 4,
    daysSinceLastPurchase: 27,
    averageTicket: 290000,
    topProduct: 'K-Llosil',
    recentProducts: ['K-Llosil'],
  ),
];
