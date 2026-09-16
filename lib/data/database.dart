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
  static const _dbVersion = 2;

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
        // The exercise model changed fundamentally in v2; rebuild the schema.
        for (final table in [
          'sets',
          'workout_exercises',
          'workouts',
          'exercises',
          'custom_exercises',
        ]) {
          await db.execute('DROP TABLE IF EXISTS $table');
        }
        await _createSchema(db);
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
  }
}
