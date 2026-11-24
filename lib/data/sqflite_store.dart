import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/geo_point.dart';
import '../models/pharmacy.dart';
import '../models/track_point.dart';
import '../models/visit.dart';
import '../models/visit_photo.dart';
import 'local_store.dart';

const _dbName = 'transferencista.db';
const _dbVersion = 1;

const _schema = <String>[
  '''
  CREATE TABLE pharmacies (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    chain TEXT NOT NULL,
    zone TEXT NOT NULL,
    address TEXT NOT NULL DEFAULT '',
    manager TEXT NOT NULL DEFAULT '',
    priority INTEGER NOT NULL,
    days_since_last_purchase INTEGER,
    average_ticket REAL NOT NULL DEFAULT 0,
    top_product TEXT,
    new_product TEXT,
    recent_products TEXT NOT NULL DEFAULT '[]',
    estimated_stock TEXT NOT NULL DEFAULT '{}'
  )''',
  '''
  CREATE TABLE plan_items (
    day TEXT NOT NULL,
    position INTEGER NOT NULL,
    pharmacy_id TEXT NOT NULL,
    PRIMARY KEY (day, position)
  )''',
  '''
  CREATE TABLE visits (
    id TEXT PRIMARY KEY,
    pharmacy_id TEXT NOT NULL,
    arrival_ms INTEGER NOT NULL,
    departure_ms INTEGER NOT NULL,
    checks TEXT NOT NULL DEFAULT '[]',
    inventory TEXT NOT NULL DEFAULT '{}',
    competitors TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    check_in_lat REAL,
    check_in_lng REAL,
    check_in_acc REAL,
    check_out_lat REAL,
    check_out_lng REAL,
    check_out_acc REAL,
    tracking_consent INTEGER NOT NULL DEFAULT 0
  )''',
  '''
  CREATE TABLE visit_photos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    visit_id TEXT NOT NULL REFERENCES visits(id) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    path TEXT NOT NULL,
    taken_at_ms INTEGER NOT NULL
  )''',
  '''
  CREATE TABLE track_points (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    visit_id TEXT NOT NULL REFERENCES visits(id) ON DELETE CASCADE,
    time_ms INTEGER NOT NULL,
    lat REAL NOT NULL,
    lng REAL NOT NULL,
    acc REAL NOT NULL,
    distance REAL NOT NULL
  )''',
  '''
  CREATE TABLE app_meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )''',
];

/// Implementación del almacenamiento local con SQLite (sqflite).
class SqfliteStore implements LocalStore {
  SqfliteStore._(this._db);

  final Database _db;

  /// Abre (o crea) la base de datos del teléfono.
  static Future<SqfliteStore> open({String? directory}) async {
    final dir = directory ?? await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, _dbName),
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final statement in _schema) {
          await db.execute(statement);
        }
      },
    );
    return SqfliteStore._(db);
  }

  @override
  Future<StoreSnapshot> loadSnapshot() async {
    final meta = await _db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seeded'],
    );
    final seeded = meta.isNotEmpty && meta.first['value'] == '1';

    final pharmacyRows = await _db.query('pharmacies');
    final visitRows = await _db.query('visits');
    final photoRows = await _db.query('visit_photos', orderBy: 'id');
    final trackRows = await _db.query('track_points', orderBy: 'id');
    final planRows = await _db.query('plan_items', orderBy: 'day, position');

    final photosByVisit = <String, List<VisitPhoto>>{};
    for (final row in photoRows) {
      photosByVisit.putIfAbsent(row['visit_id'] as String, () => []).add(
            VisitPhoto(
              kind: VisitPhotoKind.values.byName(row['kind'] as String),
              path: row['path'] as String,
              takenAt: DateTime.fromMillisecondsSinceEpoch(row['taken_at_ms'] as int),
            ),
          );
    }

    final trackByVisit = <String, List<TrackPoint>>{};
    for (final row in trackRows) {
      trackByVisit.putIfAbsent(row['visit_id'] as String, () => []).add(
            TrackPoint(
              time: DateTime.fromMillisecondsSinceEpoch(row['time_ms'] as int),
              point: GeoPoint(
                latitude: row['lat'] as double,
                longitude: row['lng'] as double,
                accuracyMeters: row['acc'] as double,
              ),
              distanceFromSiteMeters: row['distance'] as double,
            ),
          );
    }

    final plans = <DateTime, List<String>>{};
    for (final row in planRows) {
      final parts = (row['day'] as String).split('-');
      final day = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      plans.putIfAbsent(day, () => []).add(row['pharmacy_id'] as String);
    }

    return StoreSnapshot(
      seeded: seeded,
      pharmacies: [for (final row in pharmacyRows) _pharmacyFromRow(row)],
      visits: [
        for (final row in visitRows)
          _visitFromRow(
            row,
            photos: photosByVisit[row['id'] as String] ?? const [],
            track: trackByVisit[row['id'] as String] ?? const [],
          ),
      ],
      plans: plans,
    );
  }

  @override
  Future<void> savePharmacy(Pharmacy pharmacy) async {
    await _db.insert(
      'pharmacies',
      {
        'id': pharmacy.id,
        'name': pharmacy.name,
        'chain': pharmacy.chain,
        'zone': pharmacy.zone,
        'address': pharmacy.address,
        'manager': pharmacy.manager,
        'priority': pharmacy.priority,
        'days_since_last_purchase': pharmacy.daysSinceLastPurchase,
        'average_ticket': pharmacy.averageTicket,
        'top_product': pharmacy.topProduct,
        'new_product': pharmacy.newProduct,
        'recent_products': jsonEncode(pharmacy.recentProducts),
        'estimated_stock': jsonEncode(pharmacy.estimatedStock),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> savePlan(DateTime day, List<String> pharmacyIds) async {
    final key = dayKey(day);
    await _db.transaction((txn) async {
      await txn.delete('plan_items', where: 'day = ?', whereArgs: [key]);
      for (var i = 0; i < pharmacyIds.length; i++) {
        await txn.insert('plan_items', {
          'day': key,
          'position': i,
          'pharmacy_id': pharmacyIds[i],
        });
      }
    });
  }

  @override
  Future<void> saveVisit(Visit visit) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'visits',
        {
          'id': visit.id,
          'pharmacy_id': visit.pharmacyId,
          'arrival_ms': visit.arrival.millisecondsSinceEpoch,
          'departure_ms': visit.departure.millisecondsSinceEpoch,
          'checks': jsonEncode([for (final c in visit.checks) c.name]),
          'inventory': jsonEncode(visit.inventory),
          'competitors': visit.competitors,
          'notes': visit.notes,
          'check_in_lat': visit.checkIn?.latitude,
          'check_in_lng': visit.checkIn?.longitude,
          'check_in_acc': visit.checkIn?.accuracyMeters,
          'check_out_lat': visit.checkOut?.latitude,
          'check_out_lng': visit.checkOut?.longitude,
          'check_out_acc': visit.checkOut?.accuracyMeters,
          'tracking_consent': visit.trackingConsent ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('visit_photos', where: 'visit_id = ?', whereArgs: [visit.id]);
      for (final photo in visit.photos) {
        await txn.insert('visit_photos', {
          'visit_id': visit.id,
          'kind': photo.kind.name,
          'path': photo.path,
          'taken_at_ms': photo.takenAt.millisecondsSinceEpoch,
        });
      }

      await txn.delete('track_points', where: 'visit_id = ?', whereArgs: [visit.id]);
      for (final point in visit.track) {
        await txn.insert('track_points', {
          'visit_id': visit.id,
          'time_ms': point.time.millisecondsSinceEpoch,
          'lat': point.point.latitude,
          'lng': point.point.longitude,
          'acc': point.point.accuracyMeters,
          'distance': point.distanceFromSiteMeters,
        });
      }
    });
  }

  @override
  Future<void> markSeeded() async {
    await _db.insert(
      'app_meta',
      {'key': 'seeded', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Pharmacy _pharmacyFromRow(Map<String, Object?> row) {
    final recent = (jsonDecode(row['recent_products'] as String) as List).cast<String>();
    final stock = (jsonDecode(row['estimated_stock'] as String) as Map)
        .map((k, v) => MapEntry(k as String, v as int));
    return Pharmacy(
      id: row['id'] as String,
      name: row['name'] as String,
      chain: row['chain'] as String,
      zone: row['zone'] as String,
      address: row['address'] as String,
      manager: row['manager'] as String,
      priority: row['priority'] as int,
      daysSinceLastPurchase: row['days_since_last_purchase'] as int?,
      averageTicket: (row['average_ticket'] as num).toDouble(),
      topProduct: row['top_product'] as String?,
      newProduct: row['new_product'] as String?,
      recentProducts: recent,
      estimatedStock: stock,
    );
  }

  static Visit _visitFromRow(
    Map<String, Object?> row, {
    required List<VisitPhoto> photos,
    required List<TrackPoint> track,
  }) {
    final checkNames = (jsonDecode(row['checks'] as String) as List).cast<String>();
    final inventory = (jsonDecode(row['inventory'] as String) as Map)
        .map((k, v) => MapEntry(k as String, v as int));

    GeoPoint? geo(String latKey, String lngKey, String accKey) {
      final lat = row[latKey] as double?;
      final lng = row[lngKey] as double?;
      if (lat == null || lng == null) return null;
      return GeoPoint(
        latitude: lat,
        longitude: lng,
        accuracyMeters: (row[accKey] as num?)?.toDouble() ?? 0,
      );
    }

    return Visit(
      id: row['id'] as String,
      pharmacyId: row['pharmacy_id'] as String,
      arrival: DateTime.fromMillisecondsSinceEpoch(row['arrival_ms'] as int),
      departure: DateTime.fromMillisecondsSinceEpoch(row['departure_ms'] as int),
      checks: {for (final name in checkNames) PointOfSaleCheck.values.byName(name)},
      inventory: inventory,
      competitors: row['competitors'] as String,
      notes: row['notes'] as String,
      checkIn: geo('check_in_lat', 'check_in_lng', 'check_in_acc'),
      checkOut: geo('check_out_lat', 'check_out_lng', 'check_out_acc'),
      photos: photos,
      trackingConsent: (row['tracking_consent'] as int) == 1,
      track: track,
    );
  }
}
