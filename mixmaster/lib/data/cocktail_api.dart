import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Cliente da TheCocktailDB (chave de testes "1").
/// Docs: https://www.thecocktaildb.com/documentation
class CocktailApi {
  static const _host = 'www.thecocktaildb.com';
  static const _base = '/api/json/v1/1';
  static final http.Client _client = http.Client();
  static final Random _rng = Random();

  static List<String>? _ingredientNames;
  static Future<List<Drink>>? _allDrinksFuture;
  static final Map<String, Future<Ingredient?>> _ingredientCache = {};

  static Future<Map<String, dynamic>?> _get(
    String endpoint,
    Map<String, String> query,
  ) async {
    final uri = Uri.https(_host, '$_base/$endpoint', query);
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Erro ${res.statusCode} ao acessar a API');
    }
    final body = utf8.decode(res.bodyBytes).trim();
    if (body.isEmpty) return null;
    final data = json.decode(body);
    return data is Map<String, dynamic> ? data : null;
  }

  static List<Drink> _drinks(Map<String, dynamic>? data) {
    final list = data?['drinks'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(Drink.fromJson).toList();
  }

  // ---------------------------------------------------------------- Drinks

  static Future<Drink?> randomDrink() async {
    final list = _drinks(await _get('random.php', {}));
    return list.isEmpty ? null : list.first;
  }

  /// A versão gratuita só devolve 1 drink por chamada; fazemos várias em
  /// paralelo e removemos repetidos.
  static Future<List<Drink>> randomDrinks(
    int count, {
    Set<String>? exclude,
  }) async {
    final results = await Future.wait(
      List.generate(count + 4, (_) => randomDrink().catchError((_) => null)),
    );
    final seen = <String>{...?exclude};
    final out = <Drink>[];
    for (final d in results) {
      if (d != null && seen.add(d.id)) out.add(d);
      if (out.length == count) break;
    }
    if (out.isEmpty) throw Exception('Sem resposta da API');
    return out;
  }

  static Future<List<Drink>> searchByName(String name) async =>
      _drinks(await _get('search.php', {'s': name}));

  static Future<List<Drink>> searchDrinks(String query) async {
    final englishQuery = _ingredientQuery(query);
    final results = await Future.wait([
      searchByName(englishQuery),
      filterByIngredient(englishQuery),
      if (query.trim().length >= 3)
        _searchDrinksByMatchingIngredients(englishQuery),
    ]);
    final byId = <String, Drink>{};
    for (final drink in results.expand((drinks) => drinks)) {
      final previous = byId[drink.id];
      if (previous == null || (!previous.detailed && drink.detailed)) {
        byId[drink.id] = drink;
      }
    }
    return byId.values.toList();
  }

  static Future<List<Drink>> _searchDrinksByMatchingIngredients(
    String query,
  ) async {
    final names = await searchIngredientNames(query);
    final lists = await Future.wait(names.map(filterByIngredient));
    return lists.expand((drinks) => drinks).toList();
  }

  /// The free API key only lists the first 100 ingredients. Look up an exact
  /// search term as well so ingredients outside that initial list are findable.
  static Future<List<String>> searchIngredientNames(String query) async {
    final names = await ingredientNames();
    final normalizedQuery = _normalizeIngredient(_ingredientQuery(query));
    if (normalizedQuery.isEmpty) return names;

    final matches = names
        .where((name) => _normalizeIngredient(name).contains(normalizedQuery))
        .toSet();
    if (matches.isEmpty) {
      final exact = await ingredientDetails(_ingredientQuery(query));
      if (exact != null &&
          _normalizeIngredient(exact.name).contains(normalizedQuery)) {
        matches.add(exact.name);
      }
    }
    return matches.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  static String _ingredientQuery(String query) {
    final normalized = _normalizeIngredient(query);
    const aliases = {
      'acucar': 'sugar',
      'abacaxi': 'pineapple',
      'gelo': 'ice',
      'hortela': 'mint',
      'limao': 'lime',
      'limao siciliano': 'lemon',
      'laranja': 'orange',
      'morango': 'strawberry',
      'vodca': 'vodka',
    };
    return aliases[normalized] ?? query.trim();
  }

  static String _normalizeIngredient(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  static Future<Drink?> lookup(String id) async {
    final list = _drinks(await _get('lookup.php', {'i': id}));
    return list.isEmpty ? null : list.first;
  }

  static Future<List<Drink>> filterByIngredient(String ingredient) async {
    final query = _normalizeIngredient(ingredient);
    final drinks = await _allDrinks();
    return drinks
        .where(
          (drink) => drink.ingredients.any(
            (item) => _normalizeIngredient(item.name) == query,
          ),
        )
        .toList();
  }

  /// The test key's direct filter can omit matches. Scan the full alphabetic
  /// search results once, then match against each complete recipe locally.
  static Future<List<Drink>> _allDrinks() {
    final cached = _allDrinksFuture;
    if (cached != null) return cached;

    final request = _loadAllDrinks();
    _allDrinksFuture = request;
    return request.catchError((Object error) {
      _allDrinksFuture = null;
      throw error;
    });
  }

  static Future<List<Drink>> _loadAllDrinks() async {
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    final byId = <String, Drink>{};
    for (var start = 0; start < letters.length; start += 4) {
      final batch = letters.substring(
        start,
        (start + 4).clamp(0, letters.length),
      );
      final responses = await Future.wait(
        batch
            .split('')
            .map(
              (letter) async =>
                  _drinks(await _get('search.php', {'f': letter})),
            ),
      );
      for (final drink in responses.expand((result) => result)) {
        final previous = byId[drink.id];
        if (previous == null || (!previous.detailed && drink.detailed)) {
          byId[drink.id] = drink;
        }
      }
    }
    if (byId.isEmpty) throw Exception('A API não retornou drinks.');
    return byId.values.toList();
  }

  /// Retorna os drinks que levam todos os ingredientes selecionados.
  static Future<List<Drink>> filterByIngredients(List<String> names) async {
    if (names.isEmpty) return const [];
    final lists = await Future.wait(names.map(filterByIngredient));
    var ids = lists.first.map((d) => d.id).toSet();
    for (final l in lists.skip(1)) {
      ids = ids.intersection(l.map((d) => d.id).toSet());
    }
    return lists.first.where((d) => ids.contains(d.id)).toList();
  }

  /// Sorteio por humor: junta os resultados dos filtros do humor, escolhe um
  /// drink aleatório e busca os detalhes completos.
  static Future<Drink?> drinkForMood(Mood mood) async {
    if (mood.filters.isEmpty) return randomDrink();
    final lists = await Future.wait(
      mood.filters.map(
        (f) async => _drinks(await _get('filter.php', {f.key: f.value})),
      ),
    );
    final all = lists.expand((l) => l).toList();
    if (all.isEmpty) return randomDrink();
    final pick = all[_rng.nextInt(all.length)];
    return lookup(pick.id);
  }

  // ----------------------------------------------------------- Ingredientes

  static Future<List<String>> ingredientNames() async {
    if (_ingredientNames != null) return _ingredientNames!;
    final data = await _get('list.php', {'i': 'list'});
    final list = data?['drinks'];
    if (list is! List) throw Exception('Não foi possível listar ingredientes');
    final names = <String, String>{};
    for (final name
        in list
            .whereType<Map<String, dynamic>>()
            .map((e) => (e['strIngredient1'] ?? '') as String)
            .where((name) => name.isNotEmpty)) {
      names.putIfAbsent(_normalizeIngredient(name), () => name);
    }
    for (final drink in await _allDrinks()) {
      for (final ingredient in drink.ingredients) {
        names.putIfAbsent(
          _normalizeIngredient(ingredient.name),
          () => ingredient.name,
        );
      }
    }
    final sorted = names.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return _ingredientNames = sorted;
  }

  static Future<Ingredient?> ingredientDetails(String name) {
    return _ingredientCache.putIfAbsent(name, () async {
      try {
        final data = await _get('search.php', {'i': name});
        final list = data?['ingredients'];
        if (list is! List || list.isEmpty) return null;
        final first = list.first;
        if (first is! Map<String, dynamic>) return null;
        return Ingredient.fromJson(first);
      } catch (_) {
        _ingredientCache.remove(name);
        rethrow;
      }
    });
  }

  /// Imagem do ingrediente (size: Small 100px, Medium 350px, '' 700px).
  static String ingredientImage(String name, {String size = 'Small'}) {
    final suffix = size.isEmpty ? '' : '-$size';
    return 'https://$_host/images/ingredients/${Uri.encodeComponent(name)}$suffix.png';
  }
}
