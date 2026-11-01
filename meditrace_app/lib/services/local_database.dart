import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/dose_event.dart';
import '../models/medication_schedule.dart';

class LocalDatabase {
  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;
    final path = p.join(await getDatabasesPath(), 'meditrace_local.db');
    return _database = await openDatabase(
      path,
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE medication_schedules (
            id INTEGER PRIMARY KEY,
            label TEXT NOT NULL,
            hour INTEGER NOT NULL,
            minute INTEGER NOT NULL,
            compartment_number INTEGER,
            enabled INTEGER NOT NULL DEFAULT 1,
            early_tolerance INTEGER NOT NULL DEFAULT 15,
            late_tolerance INTEGER NOT NULL DEFAULT 15,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE dose_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            sensor_id INTEGER,
            schedule_id INTEGER,
            state INTEGER,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_dose_events_time ON dose_events(occurred_at DESC)',
        );
        await _createPendingAlertsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE medication_schedules ADD COLUMN compartment_number INTEGER',
          );
          await db.execute(
            'ALTER TABLE dose_events ADD COLUMN schedule_id INTEGER',
          );
        }
        if (oldVersion < 3) {
          await _createPendingAlertsTable(db);
        }
      },
    );
  }

  static Future<void> _createPendingAlertsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE pending_family_alerts (
        client_event_id TEXT PRIMARY KEY,
        group_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        title TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> queueFamilyAlert({
    required String clientEventId,
    required int groupId,
    required String kind,
    required String title,
    String? details,
  }) async {
    final db = await database;
    await db.insert('pending_family_alerts', {
      'client_event_id': clientEventId,
      'group_id': groupId,
      'kind': kind,
      'title': title,
      'details': details,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> pendingFamilyAlerts() async {
    final db = await database;
    return db.query('pending_family_alerts', orderBy: 'created_at ASC');
  }

  Future<void> reassignPendingFamilyAlerts(int groupId) async {
    final db = await database;
    await db.update('pending_family_alerts', {'group_id': groupId});
  }

  Future<void> removePendingFamilyAlert(String clientEventId) async {
    final db = await database;
    await db.delete(
      'pending_family_alerts',
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
    );
  }

  Future<void> clearPendingFamilyAlerts() async {
    final db = await database;
    await db.delete('pending_family_alerts');
  }

  Future<List<MedicationSchedule>> loadSchedules() async {
    final db = await database;
    final rows = await db.query(
      'medication_schedules',
      orderBy: 'hour ASC, minute ASC',
    );
    return rows
        .map(
          (row) => MedicationSchedule(
            id: row['id'] as int,
            label: row['label'] as String,
            hour: row['hour'] as int,
            minute: row['minute'] as int,
            compartmentNumber: row['compartment_number'] as int?,
            enabled: (row['enabled'] as int) == 1,
            earlyTolerance: row['early_tolerance'] as int,
            lateTolerance: row['late_tolerance'] as int,
            updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
          ),
        )
        .toList();
  }

  Future<void> saveSchedule(MedicationSchedule schedule) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('medication_schedules', {
      'id': schedule.id,
      'label': schedule.label,
      'hour': schedule.hour,
      'minute': schedule.minute,
      'compartment_number': schedule.compartmentNumber,
      'enabled': schedule.enabled ? 1 : 0,
      'early_tolerance': schedule.earlyTolerance,
      'late_tolerance': schedule.lateTolerance,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSchedule(int id) async {
    final db = await database;
    await db.delete('medication_schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DoseEvent>> loadEvents({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'dose_events',
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (row) => DoseEvent(
            type: row['event_type'] as String,
            timestamp: DateTime.parse(row['occurred_at'] as String),
            sensorId: row['sensor_id'] as int?,
            scheduleId: row['schedule_id'] as int?,
            state: row['state'] == null ? null : (row['state'] as int) == 1,
            status: row['status'] as String,
          ),
        )
        .toList();
  }

  Future<void> addEvent(DoseEvent event) async {
    final db = await database;
    await db.insert('dose_events', {
      'event_type': event.type,
      'occurred_at': event.timestamp.toIso8601String(),
      'sensor_id': event.sensorId,
      'schedule_id': event.scheduleId,
      'state': event.state == null ? null : (event.state! ? 1 : 0),
      'status': event.status,
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.execute('''
      DELETE FROM dose_events
      WHERE id NOT IN (
        SELECT id FROM dose_events ORDER BY occurred_at DESC LIMIT 100
      )
    ''');
  }

  Future<void> clearEvents() async {
    final db = await database;
    await db.delete('dose_events');
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
