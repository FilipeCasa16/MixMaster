import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class LocalizedDrink {
  const LocalizedDrink({
    required this.ingredientNames,
    required this.glass,
    required this.instructions,
  });

  final List<String> ingredientNames;
  final String? glass;
  final String? instructions;
}

class TranslationService {
  static const _host = 'api.mymemory.translated.net';
  static final http.Client _client = http.Client();
  static final Map<String, Future<String>> _cache = {};

  static Future<LocalizedDrink> translateDrink(Drink drink) async {
    final futures = <Future<String>>[
      for (final ingredient in drink.ingredients)
        translateText(ingredient.name),
    ];
    final glassIndex = drink.glass == null ? null : futures.length;
    if (drink.glass != null) futures.add(translateText(drink.glass!));
    final instructionsIndex = drink.instructions == null
        ? null
        : futures.length;
    if (drink.instructions != null) {
      futures.add(translateText(drink.instructions!));
    }
    final translations = await Future.wait(futures);
    return LocalizedDrink(
      ingredientNames: translations.take(drink.ingredients.length).toList(),
      glass: glassIndex == null ? null : translations[glassIndex],
      instructions: instructionsIndex == null
          ? null
          : translations[instructionsIndex],
    );
  }

  static Future<String> translateText(String text) {
    final value = cleanTranslationOutput(text);
    if (value.isEmpty) return Future.value(value);
    return _cache.putIfAbsent(value, () async {
      try {
        final uri = Uri.https(_host, '/get', {
          'q': value,
          'langpair': 'en|pt-BR',
        });
        final response = await _client.get(uri);
        if (response.statusCode != 200) {
          throw Exception('Falha na tradução (HTTP ${response.statusCode}).');
        }
        final body = json.decode(utf8.decode(response.bodyBytes));
        if (body is! Map<String, dynamic> ||
            body['responseStatus'] != 200 ||
            body['responseData'] is! Map<String, dynamic>) {
          throw Exception('O serviço de tradução não retornou um resultado.');
        }
        final translated =
            (body['responseData'] as Map<String, dynamic>)['translatedText'];
        if (translated is! String || translated.trim().isEmpty) {
          throw Exception('O serviço de tradução retornou um texto vazio.');
        }
        return cleanTranslationOutput(translated);
      } catch (_) {
        _cache.remove(value);
        rethrow;
      }
    });
  }
}

String cleanTranslationOutput(String value) {
  var cleaned = value;
  for (var i = 0; i < 4; i++) {
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), ' ');
    cleaned = _decodeEntities(cleaned);
  }
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _decodeEntities(String value) {
  final numeric = value.replaceAllMapped(
    RegExp(r'&#(?:x([0-9a-fA-F]+)|(\d+));'),
    (match) {
      final codePoint = int.tryParse(
        match.group(1) ?? match.group(2)!,
        radix: match.group(1) == null ? 10 : 16,
      );
      if (codePoint == null || codePoint > 0x10ffff) return match[0]!;
      return String.fromCharCode(codePoint);
    },
  );
  return numeric
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
