String localizedDrinkCategory(String category) {
  final normalized = category.toLowerCase().replaceAll('_', ' ');
  const categories = {
    'beer': 'Cerveja',
    'cocoa': 'Cacau',
    'coffee / tea': 'Café / Chá',
    'cocktail': 'Coquetel',
    'homemade liqueur': 'Licor caseiro',
    'ordinary drink': 'Drink comum',
    'other / unknown': 'Outro / desconhecido',
    'punch / party drink': 'Ponche / drink de festa',
    'shake': 'Milk-shake',
    'shot': 'Dose',
    'soft drink': 'Bebida sem álcool',
  };
  return categories[normalized] ?? category;
}

String localizedMeasure(String? measure) {
  if (measure == null || measure.trim().isEmpty) return '—';
  final value = measure.trim();
  final normalized = value.toLowerCase();
  const phrases = {
    'to taste': 'a gosto',
    'as needed': 'conforme necessário',
    'optional': 'opcional',
    'top up': 'complete',
  };
  if (phrases.containsKey(normalized)) return phrases[normalized]!;

  final match = RegExp(
    r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s*([a-zA-Z.]+)(.*)$',
  ).firstMatch(value);
  if (match == null) return value;

  final amount = _parseAmount(match.group(1)!);
  if (amount == null) return value;
  final unit = match.group(2)!.toLowerCase().replaceAll('.', '');
  final rest = match.group(3) ?? '';
  const units = <String, (String, double)>{
    'oz': ('oz', 29.5735),
    'ounce': ('oz', 29.5735),
    'ounces': ('oz', 29.5735),
    'cl': ('cl', 10),
    'ml': ('ml', 1),
    'l': ('l', 1000),
    'tsp': ('colher de chá', 4.92892),
    'teaspoon': ('colher de chá', 4.92892),
    'teaspoons': ('colheres de chá', 4.92892),
    'tbsp': ('colher de sopa', 14.7868),
    'tablespoon': ('colher de sopa', 14.7868),
    'tablespoons': ('colheres de sopa', 14.7868),
    'cup': ('xícara', 236.588),
    'cups': ('xícaras', 236.588),
    'pint': ('pint', 473.176),
    'pints': ('pints', 473.176),
    'quart': ('quart', 946.353),
    'quarts': ('quarts', 946.353),
    'gallon': ('galão', 3785.41),
    'gallons': ('galões', 3785.41),
    'dash': ('dash', 0.92),
    'dashes': ('dashes', 0.92),
    'drop': ('gota', 0.05),
    'drops': ('gotas', 0.05),
  };
  final conversion = units[unit];
  if (conversion == null) return value;

  var unitLabel = conversion.$1;
  if (amount > 1 && unitLabel == 'colher de chá') {
    unitLabel = 'colheres de chá';
  } else if (amount > 1 && unitLabel == 'colher de sopa') {
    unitLabel = 'colheres de sopa';
  } else if (amount > 1 && unitLabel == 'xícara') {
    unitLabel = 'xícaras';
  }
  final translated = '${match.group(1)} $unitLabel$rest';
  if (unit == 'ml' || unit == 'l') return translated;
  final milliliters = (amount * conversion.$2).round();
  return '$translated (≈ $milliliters ml)';
}

double? _parseAmount(String value) {
  final parts = value.split(' ');
  var amount = 0.0;
  for (final part in parts) {
    if (part.contains('/')) {
      final fraction = part.split('/');
      if (fraction.length != 2) return null;
      final numerator = double.tryParse(fraction[0]);
      final denominator = double.tryParse(fraction[1]);
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      amount += numerator / denominator;
    } else {
      final number = double.tryParse(part.replaceAll(',', '.'));
      if (number == null) return null;
      amount += number;
    }
  }
  return amount;
}
