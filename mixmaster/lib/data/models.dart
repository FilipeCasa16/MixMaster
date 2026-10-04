/// Ingrediente + medida dentro de uma receita (strIngredientN / strMeasureN).
class DrinkIngredient {
  final String name;
  final String? measure;
  const DrinkIngredient(this.name, this.measure);
}

/// Drink vindo da API. Resultados de `filter.php` trazem apenas id, nome e
/// imagem; `lookup.php`, `search.php` e `random.php` trazem o drink completo.
class Drink {
  final String id;
  final String name;
  final String? thumb;
  final String? category;
  final String? alcoholic;
  final String? glass;
  final String? instructions;
  final List<DrinkIngredient> ingredients;
  final bool detailed;

  const Drink({
    required this.id,
    required this.name,
    this.thumb,
    this.category,
    this.alcoholic,
    this.glass,
    this.instructions,
    this.ingredients = const [],
    this.detailed = false,
  });

  factory Drink.fromJson(Map<String, dynamic> j) {
    final ings = <DrinkIngredient>[];
    for (var i = 1; i <= 15; i++) {
      final n = (j['strIngredient$i'] as String?)?.trim();
      if (n == null || n.isEmpty) continue;
      final m = (j['strMeasure$i'] as String?)?.trim();
      ings.add(DrinkIngredient(n, (m == null || m.isEmpty) ? null : m));
    }
    return Drink(
      id: j['idDrink'].toString(),
      name: (j['strDrink'] ?? '') as String,
      thumb: j['strDrinkThumb'] as String?,
      category: j['strCategory'] as String?,
      alcoholic: j['strAlcoholic'] as String?,
      glass: j['strGlass'] as String?,
      instructions: j['strInstructions'] as String?,
      ingredients: ings,
      detailed: j.containsKey('strInstructions'),
    );
  }

  /// A API aceita /small (200px), /medium (350px) e /large (500px).
  String? thumbSized(String size) => thumb == null ? null : '$thumb/$size';
}

/// Ingrediente (search.php?i=...).
class Ingredient {
  final String name;
  final String? type;
  final String? alcohol;
  final String? description;

  const Ingredient({
    required this.name,
    this.type,
    this.alcohol,
    this.description,
  });

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: (j['strIngredient'] ?? '') as String,
        type: j['strType'] as String?,
        alcohol: j['strAlcohol'] as String?,
        description: j['strDescription'] as String?,
      );

  bool get isAlcoholic => (alcohol ?? '').toLowerCase() == 'yes';

  /// Rótulo curto (Bebida / Suco / Tempero...) derivado dos campos da API.
  String get label {
    final t = (type ?? '').toLowerCase();
    if (isAlcoholic) return 'Bebida';
    if (t.contains('juice')) return 'Suco';
    if (t.contains('herb') || t.contains('spice') || t.contains('seasoning')) {
      return 'Tempero';
    }
    if (t.contains('fruit')) return 'Fruta';
    if (t.isEmpty) return 'Ingrediente';
    return type!;
  }
}

/// Humor da tela de sorteio -> quais filtros da API usar.
class MoodFilter {
  final String key; // 'a' (alcoólico) ou 'c' (categoria)
  final String value;
  const MoodFilter(this.key, this.value);
}

class Mood {
  final String emoji;
  final String title;
  final String subtitle;
  final List<MoodFilter> filters; // vazio = totalmente aleatório
  const Mood(this.emoji, this.title, this.subtitle, this.filters);
}

const moods = <Mood>[
  Mood('😊', 'Leve e Refrescante', 'Drinks suaves ou sem álcool', [
    MoodFilter('a', 'Non_Alcoholic'),
    MoodFilter('c', 'Soft_Drink'),
  ]),
  Mood('🎉', 'Festa!', 'Cocktails animados e alcoólicos', [
    MoodFilter('c', 'Punch_/_Party_Drink'),
    MoodFilter('c', 'Cocktail'),
  ]),
  Mood('😌', 'Relaxado', 'Drinks clássicos e encorpados', [
    MoodFilter('c', 'Ordinary_Drink'),
  ]),
  Mood('🔥', 'Forte e Intenso', 'Shots e destilados puros', [
    MoodFilter('c', 'Shot'),
  ]),
  Mood('🎲', 'Surpreenda-me!', 'Um drink totalmente aleatório', []),
];
