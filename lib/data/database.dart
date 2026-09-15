import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/muscle_group.dart';

/// Opens (and lazily creates) the app's SQLite database.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'mygym.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

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
        exercise_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
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

    await _seedExercises(db);
  }

  Future<void> _seedExercises(Database db) async {
    final batch = db.batch();
    _seed.forEach((group, names) {
      for (final name in names) {
        batch.insert('exercises', {
          'name': name,
          'muscle_group': group.name,
          'is_custom': 0,
        });
      }
    });
    await batch.commit(noResult: true);
  }

  /// Default exercise library, keyed by muscle group.
  static const Map<MuscleGroup, List<String>> _seed = {
    MuscleGroup.chest: [
      'Barbell Bench Press',
      'Incline Bench Press',
      'Dumbbell Bench Press',
      'Dumbbell Fly',
      'Cable Crossover',
      'Push-Up',
      'Chest Dip',
    ],
    MuscleGroup.back: [
      'Deadlift',
      'Pull-Up',
      'Lat Pulldown',
      'Barbell Row',
      'Seated Cable Row',
      'Dumbbell Row',
      'Face Pull',
    ],
    MuscleGroup.legs: [
      'Barbell Squat',
      'Front Squat',
      'Leg Press',
      'Romanian Deadlift',
      'Walking Lunge',
      'Leg Extension',
      'Leg Curl',
      'Calf Raise',
    ],
    MuscleGroup.shoulders: [
      'Overhead Press',
      'Dumbbell Shoulder Press',
      'Lateral Raise',
      'Front Raise',
      'Rear Delt Fly',
      'Arnold Press',
      'Barbell Shrug',
    ],
    MuscleGroup.arms: [
      'Barbell Curl',
      'Dumbbell Curl',
      'Hammer Curl',
      'Preacher Curl',
      'Triceps Pushdown',
      'Overhead Triceps Extension',
      'Skull Crusher',
      'Close-Grip Bench Press',
    ],
    MuscleGroup.core: [
      'Plank',
      'Crunch',
      'Hanging Leg Raise',
      'Russian Twist',
      'Cable Crunch',
      'Ab Wheel Rollout',
    ],
    MuscleGroup.cardio: [
      'Treadmill Run',
      'Cycling',
      'Rowing Machine',
      'Elliptical',
      'Stair Climber',
      'Jump Rope',
    ],
  };
}
