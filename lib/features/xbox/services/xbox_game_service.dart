import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/xbox_game.dart';

/// Provides access to the Xbox browse page and caches parsed game metadata.
class XboxGameService {
  XboxGameService._();

  static final XboxGameService instance = XboxGameService._();

  static const String _sourceUrl = 'https://www.xbox.com/zh-TW/games/browse';
  static const String _cacheKey = 'xbox_browse_games_cache_v1';
  static const String _cacheTimestampKey = 'xbox_browse_games_cache_ts_v1';
  static const Duration _cacheTtl = Duration(hours: 6);

  final http.Client _client = http.Client();
  final Logger _logger = Logger();
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<XboxGame>> fetchGames({bool forceRefresh = false}) async {
    final prefs = await _ensurePrefs();
    final cache = await _loadCache();
    final now = DateTime.now();

    final isCacheFresh =
        cache != null && now.difference(cache.timestamp) <= _cacheTtl;
    if (!forceRefresh && isCacheFresh) {
      return cache.games;
    }

    final uri = Uri.parse(_sourceUrl);
    late http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'accept-language': 'zh-TW,zh;q=0.9,en;q=0.8',
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
    } on Object catch (error, stackTrace) {
      _logger.e(
        'Failed to fetch Xbox browse page',
        error: error,
        stackTrace: stackTrace,
      );
      if (cache != null && cache.games.isNotEmpty) {
        _logger.w('Falling back to cached Xbox games due to network error');
        return cache.games;
      }
      throw XboxGameServiceException('网络请求失败: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (cache != null && cache.games.isNotEmpty) {
        _logger
            .w('HTTP ${response.statusCode} received, using cached Xbox games');
        return cache.games;
      }
      throw XboxGameServiceException(
        '拉取 Xbox 游戏列表失败 (HTTP ${response.statusCode})',
      );
    }

    final games = await _parseHtml(response.body);
    if (games.isNotEmpty) {
      await prefs.setString(_cacheKey, XboxGame.encodeList(games));
      await prefs.setInt(_cacheTimestampKey, now.millisecondsSinceEpoch);
      return games;
    }

    if (cache != null && cache.games.isNotEmpty) {
      _logger.w('Parsed game list is empty, reusing cached data');
      return cache.games;
    }

    return const [];
  }

  Future<_CacheSnapshot?> _loadCache() async {
    final prefs = await _ensurePrefs();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) {
      return null;
    }
    try {
      final games = XboxGame.decodeList(cached);
      final ts = prefs.getInt(_cacheTimestampKey);
      final timestamp = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.fromMillisecondsSinceEpoch(0);
      return _CacheSnapshot(games: games, timestamp: timestamp);
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to decode cached Xbox games',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<List<XboxGame>> _parseHtml(String html) async {
    final document = html_parser.parse(html);

    final preloadedStateGames = _parsePreloadedState(document);
    if (preloadedStateGames.isNotEmpty) {
      return preloadedStateGames;
    }

    final script = document.getElementById('__NEXT_DATA__');
    if (script != null && script.text.isNotEmpty) {
      try {
        final dynamic nextJson = jsonDecode(script.text);
        final products = _extractProductsFromDynamic(nextJson);
        if (products.isNotEmpty) {
          return products;
        }
      } catch (e, stackTrace) {
        _logger.w(
          'Failed to parse __NEXT_DATA__ payload',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    final telemetryElements =
        document.querySelectorAll('[data-telemetry-product-metadata]');
    if (telemetryElements.isNotEmpty) {
      final products = <XboxGame>[];
      for (final element in telemetryElements) {
        final raw = element.attributes['data-telemetry-product-metadata'];
        if (raw == null || raw.isEmpty) {
          continue;
        }
        try {
          final dynamic metadata = jsonDecode(raw);
          if (metadata is Map<String, dynamic>) {
            final product = _mapToGame(metadata);
            if (product != null) {
              products.add(product);
            }
          }
        } catch (e) {
          _logger.d('Skipping invalid telemetry metadata: $e');
        }
      }
      if (products.isNotEmpty) {
        return _deduplicate(products);
      }
    }

    final cards = document.querySelectorAll('[data-productid]');
    if (cards.isNotEmpty) {
      final products = <XboxGame>[];
      for (final card in cards) {
        final product = _mapFromCard(card);
        if (product != null) {
          products.add(product);
        }
      }
      if (products.isNotEmpty) {
        return _deduplicate(products);
      }
    }

    _logger
        .w('No recognizable game entries were found in the Xbox browse markup');
    return const [];
  }

  List<XboxGame> _parsePreloadedState(Document document) {
    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final payload =
          _extractJsonAssignment(script.text, '__PRELOADED_STATE__');
      if (payload == null || payload.isEmpty) {
        continue;
      }
      try {
        final dynamic decoded = jsonDecode(payload);
        final games = _extractProductsFromDynamic(decoded);
        if (games.isNotEmpty) {
          return _deduplicate(games);
        }
      } catch (e, stackTrace) {
        _logger.w(
          'Failed to parse __PRELOADED_STATE__ payload',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    return const [];
  }

  String? _extractJsonAssignment(String source, String variableName) {
    if (source.isEmpty) {
      return null;
    }

    final markers = <String>[
      'window["$variableName"]',
      "window['$variableName']",
      'window.$variableName',
      variableName,
    ];

    for (final marker in markers) {
      final markerIndex = source.indexOf(marker);
      if (markerIndex == -1) {
        continue;
      }

      final equalsIndex = source.indexOf('=', markerIndex + marker.length);
      if (equalsIndex == -1) {
        continue;
      }

      final jsonStart = _findJsonStart(source, equalsIndex + 1);
      if (jsonStart == null) {
        continue;
      }

      final jsonText = _extractBalancedJson(source, jsonStart);
      if (jsonText != null) {
        return jsonText;
      }
    }

    return null;
  }

  int? _findJsonStart(String source, int startIndex) {
    for (int i = startIndex; i < source.length; i++) {
      final int codeUnit = source.codeUnitAt(i);
      if (_isWhitespace(codeUnit)) {
        continue;
      }
      final char = source[i];
      if (char == '{' || char == '[') {
        return i;
      }
      if (char == ';') {
        return null;
      }
    }
    return null;
  }

  String? _extractBalancedJson(String source, int startIndex) {
    if (startIndex >= source.length) {
      return null;
    }

    final startChar = source[startIndex];
    final endChar = startChar == '{'
        ? '}'
        : startChar == '['
            ? ']'
            : null;
    if (endChar == null) {
      return null;
    }

    int depth = 0;
    bool inString = false;
    bool isEscaped = false;

    for (int i = startIndex; i < source.length; i++) {
      final String char = source[i];

      if (inString) {
        if (isEscaped) {
          isEscaped = false;
          continue;
        }
        if (char == '\\') {
          isEscaped = true;
          continue;
        }
        if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"') {
        inString = true;
        continue;
      }

      if (char == startChar) {
        depth++;
        continue;
      }

      if (char == endChar) {
        depth--;
        if (depth == 0) {
          return source.substring(startIndex, i + 1);
        }
        continue;
      }
    }

    return null;
  }

  bool _isWhitespace(int codeUnit) {
    return codeUnit == 0x20 || // space
        codeUnit == 0x09 || // tab
        codeUnit == 0x0A || // line feed
        codeUnit == 0x0D || // carriage return
        codeUnit == 0x0C; // form feed
  }

  List<XboxGame> _extractProductsFromDynamic(dynamic root) {
    final results = <XboxGame>[];
    final seenIds = <String>{};

    void walk(dynamic node) {
      if (node is Map<String, dynamic>) {
        final game = _mapToGame(node);
        if (game != null) {
          final cacheKey = game.id.isNotEmpty ? game.id : game.title;
          if (seenIds.add(cacheKey)) {
            results.add(game);
          }
        }
        for (final value in node.values) {
          walk(value);
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(root);
    return results;
  }

  XboxGame? _mapToGame(Map<String, dynamic> data) {
    final family = _asLowerCaseString(data['productFamily']);
    final kind = _asLowerCaseString(data['productKind']);
    if (family != null || kind != null) {
      final isGameFamily = (family != null && family.contains('game')) ||
          (kind != null && kind.contains('game'));
      if (!isGameFamily) {
        return null;
      }
    }

    final title = _extractTitle(data);
    if (title == null || title.isEmpty) {
      return null;
    }

    final id = _extractId(data);
    final storeUri = _normalizeStoreUri(_extractStorePath(data));
    final image = _extractImageUri(data);
    final price = _extractPriceText(data);
    final platforms = _extractPlatforms(data);
    final description = _extractDescription(data);

    return XboxGame(
      id: id,
      title: title,
      storeUri: storeUri,
      thumbnailUri: image,
      priceText: price,
      platforms: platforms,
      description: description,
    );
  }

  XboxGame? _mapFromCard(Element element) {
    final id = element.attributes['data-productid'] ?? '';
    final link = element.querySelector('a');
    final titleElement = element.querySelector('h3, h2, span.title');
    final imageElement = element.querySelector('img');

    if (titleElement == null) {
      return null;
    }

    final title = titleElement.text.trim();
    if (title.isEmpty) {
      return null;
    }

    return XboxGame(
      id: id,
      title: title,
      storeUri: _normalizeStoreUri(link?.attributes['href'] ?? '#'),
      thumbnailUri: imageElement?.attributes['src'],
      priceText:
          element.querySelector('[class*="price"], [data-price]')?.text.trim(),
      platforms: const [],
      description: element.querySelector('p')?.text.trim(),
    );
  }

  String _extractId(Map<String, dynamic> data) {
    final candidates = [
      data['productId'],
      data['productid'],
      data['legacyProductId'],
      data['skuId'],
      data['id'],
      data['recordId'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return data.hashCode.toString();
  }

  String _extractStorePath(Map<String, dynamic> data) {
    final candidates = [
      data['storeUri'],
      data['uri'],
      data['url'],
      data['productUrl'],
      data['productSlug'],
      data['slug'],
      data['canonicalProduct'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '#';
  }

  String _normalizeStoreUri(String path) {
    if (path.isEmpty || path == '#') {
      return _sourceUrl;
    }
    final Uri base = Uri.parse(_sourceUrl);
    try {
      if (path.startsWith('http')) {
        return path;
      }
      return base.resolve(path).toString();
    } catch (_) {
      return _sourceUrl;
    }
  }

  String? _extractTitle(Map<String, dynamic> data) {
    final candidates = [
      data['productDisplayName'],
      data['title'],
      data['productTitle'],
      data['displayName'],
      data['name'],
      data['titleText'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _extractImageUri(Map<String, dynamic> data) {
    final candidates = [
      data['imageUri'],
      data['image'],
      data['imageUrl'],
      data['thumbnail'],
      data['boxShot'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return _normalizeStoreUri(value);
      }
    }

    final images = data['images'];
    if (images is List && images.isNotEmpty) {
      for (final imageEntry in images) {
        if (imageEntry is Map<String, dynamic>) {
          final image = _extractImageUri(imageEntry);
          if (image != null) {
            return image;
          }
        } else if (imageEntry is String) {
          final value = imageEntry.trim();
          if (value.isNotEmpty) {
            return _normalizeStoreUri(value);
          }
        }
      }
    }

    return null;
  }

  String? _extractPriceText(Map<String, dynamic> data) {
    final price = data['price'];
    if (price is Map<String, dynamic>) {
      final candidates = [
        price['priceString'],
        price['priceText'],
        price['currentPrice'],
        price['listPrice'],
      ];
      for (final candidate in candidates) {
        if (candidate == null) {
          continue;
        }
        final value = candidate.toString().trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    } else if (price is String && price.trim().isNotEmpty) {
      return price.trim();
    }

    final merchandising = data['merchandising'];
    if (merchandising is Map<String, dynamic>) {
      return _extractPriceText(merchandising);
    }

    final pricing = data['pricing'];
    if (pricing is Map<String, dynamic>) {
      final displayPrice = pricing['displayPrice'] ?? pricing['priceText'];
      if (displayPrice != null) {
        final value = displayPrice.toString().trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  List<String> _extractPlatforms(Map<String, dynamic> data) {
    final result = <String>{};

    void addAll(dynamic value) {
      if (value is List) {
        for (final entry in value) {
          addAll(entry);
        }
      } else if (value is String) {
        final normalized = value.trim();
        if (normalized.isNotEmpty) {
          result.add(normalized);
        }
      }
    }

    final candidates = [
      data['platforms'],
      data['availableOn'],
      data['supportedDevices'],
      data['devices'],
    ];
    for (final candidate in candidates) {
      if (candidate != null) {
        addAll(candidate);
      }
    }

    return result.toList()..sort();
  }

  String? _extractDescription(Map<String, dynamic> data) {
    final candidates = [
      data['description'],
      data['shortDescription'],
      data['summary'],
      data['body'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  List<XboxGame> _deduplicate(List<XboxGame> games) {
    final seen = <String>{};
    final deduped = <XboxGame>[];
    for (final game in games) {
      final key = game.id.isNotEmpty ? game.id : game.title;
      if (seen.add(key)) {
        deduped.add(game);
      }
    }
    return deduped;
  }

  String? _asLowerCaseString(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString().toLowerCase();
  }
}

class XboxGameServiceException implements Exception {
  XboxGameServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _CacheSnapshot {
  const _CacheSnapshot({required this.games, required this.timestamp});

  final List<XboxGame> games;
  final DateTime timestamp;
}
