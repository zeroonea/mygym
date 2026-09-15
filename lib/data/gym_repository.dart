import 'package:sqflite/sqflite.dart';

import '../models/aggregates.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import 'database.dart';

/// All data access for the app. Wraps the SQLite database with typed methods.
class GymRepository {
  GymRepository({AppDatabase? db}) : _appDb = db ?? AppDatabase.instance;

  final AppDatabase _appDb;

  Future<Database> get _db => _appDb.database;

  // --- Exercises -----------------------------------------------------------

  Future<List<Exercise>> getExercises({String? query}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${query.trim()}%');
    }
    final rows = await db.query(
      'exercises',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<Exercise?> getExercise(int id) async {
    final db = await _db;
    final rows = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<int> addExercise(Exercise exercise) async {
    final db = await _db;
    return db.insert('exercises', exercise.toMap());
  }

  Future<void> updateExercise(Exercise exercise) async {
    final db = await _db;
    await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<void> deleteExercise(int id) async {
    final db = await _db;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // --- Workouts ------------------------------------------------------------

  Future<List<Workout>> getWorkouts() async {
    final db = await _db;
    final rows = await db.query('workouts', orderBy: 'date DESC');
    return rows.map(Workout.fromMap).toList();
  }

  Future<Workout?> getWorkout(int id) async {
    final db = await _db;
    final rows = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Workout.fromMap(rows.first);
  }

  Future<int> createWorkout({DateTime? date, String? name}) async {
    final db = await _db;
    return db.insert('workouts', {
      'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
      'name': name,
      'completed': 0,
    });
  }

  Future<void> updateWorkout(Workout workout) async {
    final db = await _db;
    await db.update(
      'workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<void> deleteWorkout(int id) async {
    final db = await _db;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  /// The most recent workout that has not been marked complete, if any.
  Future<Workout?> getActiveWorkout() async {
    final db = await _db;
    final rows = await db.query(
      'workouts',
      where: 'completed = 0',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Workout.fromMap(rows.first);
  }

  // --- Workout exercises & sets -------------------------------------------

  Future<int> addExerciseToWorkout(int workoutId, int exerciseId) async {
    final db = await _db;
    final existing = await db.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    return db.insert('workout_exercises', {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'position': existing.length,
    });
  }

  Future<void> removeWorkoutExercise(int workoutExerciseId) async {
    final db = await _db;
    await db.delete(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [workoutExerciseId],
    );
  }

  Future<int> addSet(
    int workoutExerciseId, {
    required double weight,
    required int reps,
  }) async {
    final db = await _db;
    final existing = await db.query(
      'sets',
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
    );
    return db.insert('sets', {
      'workout_exercise_id': workoutExerciseId,
      'set_number': existing.length + 1,
      'weight': weight,
      'reps': reps,
      'done': 1,
    });
  }

  Future<void> updateSet(ExerciseSet set) async {
    final db = await _db;
    await db.update('sets', set.toMap(), where: 'id = ?', whereArgs: [set.id]);
  }

  Future<void> deleteSet(int id) async {
    final db = await _db;
    await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  /// Loads a workout expanded with its exercises and sets, ordered correctly.
  Future<WorkoutDetail?> getWorkoutDetail(int workoutId) async {
    final db = await _db;
    final workout = await getWorkout(workoutId);
    if (workout == null) return null;

    final weRows = await db.rawQuery('''
      SELECT we.id AS we_id, we.workout_id, we.exercise_id, we.position,
             e.id AS e_id, e.name, e.muscle_group, e.is_custom, e.notes
      FROM workout_exercises we
      JOIN exercises e ON e.id = we.exercise_id
      WHERE we.workout_id = ?
      ORDER BY we.position ASC
    ''', [workoutId]);

    final groups = <SetGroup>[];
    for (final row in weRows) {
      final workoutExercise = WorkoutExercise(
        id: row['we_id'] as int,
        workoutId: row['workout_id'] as int,
        exerciseId: row['exercise_id'] as int,
        position: row['position'] as int,
      );
      final exercise = Exercise(
        id: row['e_id'] as int,
        name: row['name'] as String,
        muscleGroup: row['muscle_group'] as String,
        isCustom: (row['is_custom'] as int? ?? 0) == 1,
        notes: row['notes'] as String?,
      );
      final setRows = await db.query(
        'sets',
        where: 'workout_exercise_id = ?',
        whereArgs: [workoutExercise.id],
        orderBy: 'set_number ASC',
      );
      groups.add(SetGroup(
        workoutExercise: workoutExercise,
        exercise: exercise,
        sets: setRows.map(ExerciseSet.fromMap).toList(),
      ));
    }

    return WorkoutDetail(workout: workout, groups: groups);
  }

  // --- Stats ---------------------------------------------------------------

  /// Summary numbers for workouts on or after [since].
  Future<WorkoutSummary> summarySince(DateTime since) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT COUNT(DISTINCT w.id) AS workout_count,
             COUNT(s.id) AS total_sets,
             COALESCE(SUM(s.weight * s.reps), 0) AS total_volume
      FROM workouts w
      LEFT JOIN workout_exercises we ON we.workout_id = w.id
      LEFT JOIN sets s ON s.workout_exercise_id = we.id
      WHERE w.date >= ?
    ''', [since.millisecondsSinceEpoch]);
    final row = rows.first;
    return WorkoutSummary(
      workoutCount: (row['workout_count'] as int?) ?? 0,
      totalSets: (row['total_sets'] as int?) ?? 0,
      totalVolume: ((row['total_volume'] as num?) ?? 0).toDouble(),
    );
  }

  /// Per-day progress history for a single exercise, oldest first.
  Future<List<ProgressPoint>> exerciseProgress(int exerciseId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT w.date AS date, s.weight AS weight, s.reps AS reps
      FROM sets s
      JOIN workout_exercises we ON we.id = s.workout_exercise_id
      JOIN workouts w ON w.id = we.workout_id
      WHERE we.exercise_id = ?
      ORDER BY w.date ASC
    ''', [exerciseId]);

    // Group sets by calendar day.
    final byDay = <int, List<ExerciseSet>>{};
    final dayDate = <int, DateTime>{};
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
      final key = DateTime(date.year, date.month, date.day)
          .millisecondsSinceEpoch;
      final set = ExerciseSet(
        workoutExerciseId: 0,
        setNumber: 0,
        weight: (row['weight'] as num).toDouble(),
        reps: row['reps'] as int,
      );
      byDay.putIfAbsent(key, () => []).add(set);
      dayDate[key] = DateTime(date.year, date.month, date.day);
    }

    final points = <ProgressPoint>[];
    final keys = byDay.keys.toList()..sort();
    for (final key in keys) {
      final sets = byDay[key]!;
      double bestWeight = 0;
      double bestOrm = 0;
      double volume = 0;
      int reps = 0;
      for (final s in sets) {
        if (s.weight > bestWeight) bestWeight = s.weight;
        if (s.estimatedOneRepMax > bestOrm) bestOrm = s.estimatedOneRepMax;
        volume += s.volume;
        reps += s.reps;
      }
      points.add(ProgressPoint(
        date: dayDate[key]!,
        bestWeight: bestWeight,
        bestOneRepMax: bestOrm,
        volume: volume,
        totalReps: reps,
      ));
    }
    return points;
  }

  /// Exercises that have at least one logged set, for the progress picker.
  Future<List<Exercise>> exercisesWithHistory() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT DISTINCT e.id, e.name, e.muscle_group, e.is_custom, e.notes
      FROM exercises e
      JOIN workout_exercises we ON we.exercise_id = e.id
      JOIN sets s ON s.workout_exercise_id = we.id
      ORDER BY e.name COLLATE NOCASE ASC
    ''');
    return rows.map(Exercise.fromMap).toList();
  }
}
