import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/catalog_exercise.dart';
import '../models/muscle_group.dart';
import 'remote_config.dart';

/// Where the base dataset came from on the last load.
enum DataSource { bundled, synced }

/// The result of a manual remote data [ExerciseCatalog.syncRemote].
class SyncResult {
  const SyncResult({required this.ok, required this.message});
  final bool ok;
  final String message;
}

/// The exercise library: the bundled dataset (optionally replaced by a copy
/// synced from GitHub and any cached overrides), plus the user's custom
/// exercises.
///
/// Nothing here touches the network at launch — [load] reads only bundled
/// assets and on-device caches. Fresh data is pulled on demand via
/// [syncRemote] (wired to the Sync button in Settings).
class ExerciseCatalog {
  final Map<String, CatalogExercise> _byId = {};
  List<CatalogExercise> _all = [];

  List<CatalogExercise> get all => List.unmodifiable(_all);
  CatalogExercise? byId(String id) => _byId[id];

  /// Whether the base dataset on the last [load] was the bundled asset or a
  /// previously synced copy, and when that copy was written.
  DataSource dataSource = DataSource.bundled;
  DateTime? lastSyncedAt;

  /// Loads the base dataset (synced copy if present, else the bundled asset),
  /// merges any cached overrides/additions, then layers custom exercises on
  /// top. Offline and network-free.
  Future<void> load({List<CatalogExercise> custom = const []}) async {
    final raw = await _readBaseJson();
    final baseList = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    final merged = <String, CatalogExercise>{
      for (final j in baseList)
        j['id'].toString(): CatalogExercise.fromJson(j),
    };

    final overrides = await _readCachedOverrides();
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

  /// Reads the base dataset JSON: the synced copy if it exists, else the
  /// bundled asset. Sets [dataSource]/[lastSyncedAt] as a side effect.
  Future<String> _readBaseJson() async {
    try {
      final file = await _datasetCacheFile();
      if (await file.exists()) {
        dataSource = DataSource.synced;
        lastSyncedAt = (await file.stat()).modified;
        return await file.readAsString();
      }
    } catch (_) {}
    dataSource = DataSource.bundled;
    return rootBundle.loadString('assets/data/exercises.json');
  }

  Future<Map<String, dynamic>?> _readCachedOverrides() async {
    try {
      final file = await _overridesCacheFile();
      if (await file.exists()) {
        return json.decode(await file.readAsString())
            as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Pulls the latest dataset + overrides from GitHub and caches them on the
  /// device. Called from the Sync button; the caller reloads the catalog after.
  Future<SyncResult> syncRemote() async {
    int? exerciseCount;
    try {
      final datasetBody = await _fetch(RemoteConfig.datasetUrl);
      final list = json.decode(datasetBody);
      if (list is! List || list.isEmpty) {
        return const SyncResult(ok: false, message: 'Dataset response invalid.');
      }
      exerciseCount = list.length;
      await (await _datasetCacheFile()).writeAsString(datasetBody);

      // Overrides are optional — a failure here shouldn't fail the whole sync.
      try {
        final overridesBody = await _fetch(RemoteConfig.overridesUrl);
        json.decode(overridesBody); // validate
        await (await _overridesCacheFile()).writeAsString(overridesBody);
      } catch (e) {
        debugPrint('overrides sync skipped: $e');
      }

      return SyncResult(
          ok: true, message: 'Synced $exerciseCount exercises.');
    } catch (e) {
      debugPrint('dataset sync failed: $e');
      return const SyncResult(
          ok: false,
          message: 'Sync failed. Check your connection and try again.');
    }
  }

  Future<String> _fetch(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  Future<File> _datasetCacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'exercises_synced.json'));
  }

  Future<File> _overridesCacheFile() async {
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
