import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (and lazily creates) the app's SQLite database.
///
/// Exercises come from the bundled dataset / catalog, so only the user's own
/// data lives here: workouts, the exercises logged in them, sets, and any
/// custom exercises the user creates.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'mygym.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2: the exercise model changed fundamentally, so the training
        // tables are rebuilt from scratch (only local test data existed then).
        if (oldVersion < 2) {
          for (final table in [
            'sets',
            'workout_exercises',
            'workouts',
            'exercises',
            'custom_exercises',
          ]) {
            await db.execute('DROP TABLE IF EXISTS $table');
          }
          await _createSchema(db); // creates the current (latest) schema
          return;
        }
        // v2 → v3: additive only, so existing workouts/sets are preserved.
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE sets ADD COLUMN body_weight REAL');
          await db.execute('ALTER TABLE sets ADD COLUMN created_at INTEGER');
          await _createProfileTable(db);
          await _createBodyMetricsTable(db);
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        name TEXT,
        notes TEXT,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        muscle_group TEXT,
        position INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        done INTEGER NOT NULL DEFAULT 1,
        body_weight REAL,
        created_at INTEGER,
        FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        equipment TEXT,
        level TEXT,
        muscle_group TEXT,
        primary_muscles TEXT,
        secondary_muscles TEXT,
        notes TEXT
      )
    ''');

    await _createProfileTable(db);
    await _createBodyMetricsTable(db);
  }

  Future<void> _createProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY,
        sex TEXT,
        birth_year INTEGER,
        height_cm REAL,
        activity_level TEXT,
        goal TEXT,
        target_weight REAL
      )
    ''');
  }

  Future<void> _createBodyMetricsTable(Database db) async {
    await db.execute('''
      CREATE TABLE body_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        weight REAL NOT NULL,
        body_fat REAL,
        neck REAL,
        chest REAL,
        waist REAL,
        hip REAL,
        arm REAL,
        thigh REAL,
        calf REAL,
        notes TEXT
      )
    ''');
  }
}
