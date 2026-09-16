import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/food_item.dart';

/// Searches food macro data. Live results come from the free, key-less
/// [Open Food Facts](https://world.openfoodfacts.org) API; a small bundled list
/// of common foods provides offline fallback and instant results for staples.
class FoodRepository {
  static const _searchBase =
      'https://world.openfoodfacts.org/cgi/search.pl';
  static const _userAgent = 'MyGym/1.0 (personal gym tracker)';

  List<FoodItem>? _common;

  /// Loads (and caches) the bundled common-foods list.
  Future<List<FoodItem>> commonFoods() async {
    if (_common != null) return _common!;
    try {
      final raw = await rootBundle.loadString('assets/data/foods_common.json');
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      _common = list.map(FoodItem.fromJson).toList();
    } catch (_) {
      _common = const [];
    }
    return _common!;
  }

  /// Foods from the bundled list whose name matches [query].
  Future<List<FoodItem>> searchCommon(String query) async {
    final q = query.trim().toLowerCase();
    final all = await commonFoods();
    if (q.isEmpty) return all;
    return all.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  /// Searches Open Food Facts for [query]. Falls back to the bundled list when
  /// the network is unavailable.
  Future<List<FoodItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return searchCommon('');

    final uri = Uri.parse(_searchBase).replace(queryParameters: {
      'search_terms': q,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '30',
      'fields':
          'product_name,brands,nutriments,serving_quantity',
    });

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6)
        ..userAgent = _userAgent;
      final request = await client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        client.close();
        final data = json.decode(body) as Map<String, dynamic>;
        final products =
            (data['products'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        final items = <FoodItem>[];
        for (final p in products) {
          final item = FoodItem.fromOpenFoodFacts(p);
          if (item != null) items.add(item);
        }
        if (items.isNotEmpty) return items;
      } else {
        client.close();
      }
    } catch (e) {
      debugPrint('food search failed: $e');
    }

    // Offline / no results → bundled staples.
    return searchCommon(q);
  }
}
