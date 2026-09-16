import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/aggregates.dart';
import '../models/body_entry.dart';
import '../models/catalog_exercise.dart';
import '../models/exercise_set.dart';
import '../models/muscle_group.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import 'database.dart';
import 'exercise_catalog.dart';

/// All data access for the app: workouts, sets, and custom exercises. Exercise
/// identity is resolved against the [ExerciseCatalog].
class GymRepository {
  GymRepository({required this.catalog, AppDatabase? db})
      : _appDb = db ?? AppDatabase.instance;

  final ExerciseCatalog catalog;
  final AppDatabase _appDb;

  Future<Database> get _db => _appDb.database;

  CatalogExercise _resolve(String id, String name, String? group) =>
      catalog.byId(id) ??
      CatalogExercise.placeholder(
        id: id,
        name: name,
        group: MuscleGroup.fromName(group),
      );

  // --- Custom exercises ----------------------------------------------------

  Future<List<CatalogExercise>> getCustomExercises() async {
    final db = await _db;
    final rows = await db.query('custom_exercises', orderBy: 'name COLLATE NOCASE');
    return rows.map(_customFromRow).toList();
  }

  CatalogExercise _customFromRow(Map<String, Object?> r) {
    List<String> list(Object? v) {
      if (v == null || (v as String).isEmpty) return const [];
      return (json.decode(v) as List).map((e) => e.toString()).toList();
    }

    return CatalogExercise(
      id: r['id'] as String,
      name: r['name'] as String,
      category: r['category'] as String?,
      equipment: r['equipment'] as String?,
      level: r['level'] as String?,
      primaryMuscles: list(r['primary_muscles']),
      secondaryMuscles: list(r['secondary_muscles']),
      notes: r['notes'] as String?,
      isCustom: true,
      groupOverride: MuscleGroup.fromName(r['muscle_group'] as String?),
    );
  }

  Future<void> saveCustomExercise(CatalogExercise e) async {
    final db = await _db;
    await db.insert(
      'custom_exercises',
      {
        'id': e.id,
        'name': e.name,
        'category': e.category,
        'equipment': e.equipment,
        'level': e.level,
        'muscle_group': e.group.name,
        'primary_muscles': json.encode(e.primaryMuscles),
        'secondary_muscles': json.encode(e.secondaryMuscles),
        'notes': e.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCustomExercise(String id) async {
    final db = await _db;
    await db.delete('custom_exercises', where: 'id = ?', whereArgs: [id]);
  }

  String newCustomId() => 'custom_${DateTime.now().microsecondsSinceEpoch}';

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
    await db.update('workouts', workout.toMap(),
        where: 'id = ?', whereArgs: [workout.id]);
  }

  Future<void> deleteWorkout(int id) async {
    final db = await _db;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Workout exercises & sets -------------------------------------------

  Future<void> addExerciseToWorkout(int workoutId, CatalogExercise e) async {
    final db = await _db;
    final existing = await db.query('workout_exercises',
        where: 'workout_id = ?', whereArgs: [workoutId]);
    await db.insert('workout_exercises', {
      'workout_id': workoutId,
      'exercise_id': e.id,
      'exercise_name': e.name,
      'muscle_group': e.group.name,
      'position': existing.length,
    });
  }

  Future<void> removeWorkoutExercise(int workoutExerciseId) async {
    final db = await _db;
    await db.delete('workout_exercises',
        where: 'id = ?', whereArgs: [workoutExerciseId]);
  }

  Future<void> addSet(int workoutExerciseId,
      {required double weight,
      required int reps,
      double? bodyWeight,
      DateTime? createdAt}) async {
    final db = await _db;
    final existing = await db.query('sets',
        where: 'workout_exercise_id = ?', whereArgs: [workoutExerciseId]);
    await db.insert('sets', {
      'workout_exercise_id': workoutExerciseId,
      'set_number': existing.length + 1,
      'weight': weight,
      'reps': reps,
      'done': 1,
      'body_weight': bodyWeight,
      'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
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

  Future<WorkoutDetail?> getWorkoutDetail(int workoutId) async {
    final db = await _db;
    final workout = await getWorkout(workoutId);
    if (workout == null) return null;

    final weRows = await db.query('workout_exercises',
        where: 'workout_id = ?',
        whereArgs: [workoutId],
        orderBy: 'position ASC');

    final groups = <SetGroup>[];
    for (final row in weRows) {
      final we = WorkoutExercise.fromMap(row);
      final exercise = _resolve(
        we.exerciseId,
        row['exercise_name'] as String,
        row['muscle_group'] as String?,
      );
      final setRows = await db.query('sets',
          where: 'workout_exercise_id = ?',
          whereArgs: [we.id],
          orderBy: 'set_number ASC');
      groups.add(SetGroup(
        workoutExercise: we,
        exercise: exercise,
        sets: setRows.map(ExerciseSet.fromMap).toList(),
      ));
    }

    return WorkoutDetail(workout: workout, groups: groups);
  }

  // --- Stats ---------------------------------------------------------------

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

  Future<List<ProgressPoint>> exerciseProgress(String exerciseId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT w.date AS date, s.weight AS weight, s.reps AS reps
      FROM sets s
      JOIN workout_exercises we ON we.id = s.workout_exercise_id
      JOIN workouts w ON w.id = we.workout_id
      WHERE we.exercise_id = ?
      ORDER BY w.date ASC
    ''', [exerciseId]);

    final byDay = <int, List<ExerciseSet>>{};
    final dayDate = <int, DateTime>{};
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
      final key =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      byDay.putIfAbsent(key, () => []).add(ExerciseSet(
            workoutExerciseId: 0,
            setNumber: 0,
            weight: (row['weight'] as num).toDouble(),
            reps: row['reps'] as int,
          ));
      dayDate[key] = DateTime(date.year, date.month, date.day);
    }

    final points = <ProgressPoint>[];
    final keys = byDay.keys.toList()..sort();
    for (final key in keys) {
      final sets = byDay[key]!;
      double bestWeight = 0, bestOrm = 0, volume = 0;
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

  // --- Profile & body metrics ---------------------------------------------

  Future<Profile> getProfile() async {
    final db = await _db;
    final rows = await db.query('profile', where: 'id = 1');
    if (rows.isEmpty) return const Profile();
    return Profile.fromMap(rows.first);
  }

  Future<void> saveProfile(Profile profile) async {
    final db = await _db;
    await db.insert('profile', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BodyEntry>> getBodyEntries() async {
    final db = await _db;
    final rows = await db.query('body_metrics', orderBy: 'date DESC, id DESC');
    return rows.map(BodyEntry.fromMap).toList();
  }

  /// The most recent logged bodyweight, if any (used for bodyweight-exercise
  /// volume snapshots).
  Future<double?> latestBodyWeight() async {
    final db = await _db;
    final rows = await db.query('body_metrics',
        columns: ['weight'], orderBy: 'date DESC, id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return (rows.first['weight'] as num).toDouble();
  }

  Future<int> addBodyEntry(BodyEntry entry) async {
    final db = await _db;
    return db.insert('body_metrics', entry.toMap());
  }

  Future<void> updateBodyEntry(BodyEntry entry) async {
    final db = await _db;
    await db.update('body_metrics', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteBodyEntry(int id) async {
    final db = await _db;
    await db.delete('body_metrics', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CatalogExercise>> exercisesWithHistory() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT we.exercise_id AS id,
             MAX(we.exercise_name) AS name,
             MAX(we.muscle_group) AS muscle_group
      FROM workout_exercises we
      JOIN sets s ON s.workout_exercise_id = we.id
      GROUP BY we.exercise_id
      ORDER BY name COLLATE NOCASE ASC
    ''');
    return rows
        .map((r) => _resolve(r['id'] as String, r['name'] as String,
            r['muscle_group'] as String?))
        .toList();
  }
}
