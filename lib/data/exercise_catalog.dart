import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/catalog_exercise.dart';
import '../models/muscle_group.dart';
import 'remote_config.dart';

/// Source used for the enrichment overrides on the last load.
enum OverridesSource { remote, cache, none }

/// The exercise library: the bundled dataset, enriched by the remote overrides
/// file, plus the user's custom exercises.
class ExerciseCatalog {
  final Map<String, CatalogExercise> _byId = {};
  List<CatalogExercise> _all = [];

  List<CatalogExercise> get all => List.unmodifiable(_all);
  CatalogExercise? byId(String id) => _byId[id];

  OverridesSource overridesSource = OverridesSource.none;

  /// Loads the base dataset, merges remote/cached overrides and additions,
  /// then layers the supplied custom exercises on top.
  Future<void> load({List<CatalogExercise> custom = const []}) async {
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final baseList = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    final merged = <String, CatalogExercise>{
      for (final j in baseList)
        j['id'].toString(): CatalogExercise.fromJson(j),
    };

    final overrides = await _loadOverrides();
    if (overrides != null) {
      final patches =
          (overrides['overrides'] as Map?)?.cast<String, dynamic>() ?? {};
      patches.forEach((id, patch) {
        final base = merged[id];
        if (base != null && patch is Map) {
          merged[id] = base.applyOverride(patch.cast<String, dynamic>());
        }
      });
      final additions = (overrides['additions'] as List?) ?? const [];
      for (final a in additions) {
        if (a is Map) {
          final ce = CatalogExercise.fromJson(a.cast<String, dynamic>());
          merged[ce.id] = ce;
        }
      }
    }

    for (final c in custom) {
      merged[c.id] = c;
    }

    _byId
      ..clear()
      ..addAll(merged);
    _all = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<Map<String, dynamic>?> _loadOverrides() async {
    final cacheFile = await _cacheFile();
    // Try the network first (short timeout), fall back to the on-device cache.
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      final request =
          await client.getUrl(Uri.parse(RemoteConfig.overridesUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        client.close();
        try {
          await cacheFile.writeAsString(body);
        } catch (_) {}
        overridesSource = OverridesSource.remote;
        return data;
      }
      client.close();
    } catch (e) {
      debugPrint('overrides fetch failed: $e');
    }

    try {
      if (await cacheFile.exists()) {
        overridesSource = OverridesSource.cache;
        return json.decode(await cacheFile.readAsString())
            as Map<String, dynamic>;
      }
    } catch (_) {}

    overridesSource = OverridesSource.none;
    return null;
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'exercise_overrides.json'));
  }

  /// Filtered, name-sorted view of the library.
  List<CatalogExercise> query({
    String? text,
    MuscleGroup? group,
    String? equipment,
    String? level,
  }) {
    final q = text?.trim().toLowerCase() ?? '';
    return _all.where((e) {
      if (q.isNotEmpty && !e.name.toLowerCase().contains(q)) return false;
      if (group != null && e.group != group) return false;
      if (equipment != null && e.equipment != equipment) return false;
      if (level != null && e.level != level) return false;
      return true;
    }).toList();
  }

  List<String> get equipmentOptions {
    final set = <String>{};
    for (final e in _all) {
      final eq = e.equipment;
      if (eq != null && eq.isNotEmpty) set.add(eq);
    }
    final list = set.toList()..sort();
    return list;
  }

  static const levelOptions = ['beginner', 'intermediate', 'expert'];
}
