import 'dart:convert';

/// Lightweight representation of a game pulled from the Xbox browse page.
class XboxGame {
  XboxGame({
    required this.id,
    required this.title,
    required this.storeUri,
    this.thumbnailUri,
    this.priceText,
    this.platforms = const [],
    this.description,
  });

  final String id;
  final String title;
  final String storeUri;
  final String? thumbnailUri;
  final String? priceText;
  final List<String> platforms;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'storeUri': storeUri,
      'thumbnailUri': thumbnailUri,
      'priceText': priceText,
      'platforms': platforms,
      'description': description,
    };
  }

  factory XboxGame.fromJson(Map<String, dynamic> json) {
    return XboxGame(
      id: json['id'] as String? ?? json['productId'] as String? ?? '',
      title: json['title'] as String? ??
          json['productDisplayName'] as String? ??
          '未知标题',
      storeUri: json['storeUri'] as String? ?? json['slug'] as String? ?? '#',
      thumbnailUri: json['thumbnailUri'] as String?,
      priceText: json['priceText'] as String?,
      platforms:
          (json['platforms'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      description: json['description'] as String?,
    );
  }

  static List<XboxGame> decodeList(String raw) {
    final dynamic data = jsonDecode(raw);
    if (data is List) {
      return data
          .map((item) => XboxGame.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  static String encodeList(Iterable<XboxGame> games) {
    return jsonEncode(games.map((game) => game.toJson()).toList());
  }
}
