import 'package:flutter_test/flutter_test.dart';
import 'package:mixmaster/data/recipe_localization.dart';

void main() {
  group('localizedMeasure', () {
    test('converts ounces to approximate milliliters', () {
      expect(localizedMeasure('1 oz'), '1 oz (≈ 30 ml)');
      expect(localizedMeasure('1/2 oz'), '1/2 oz (≈ 15 ml)');
      expect(localizedMeasure('1 1/2 oz'), '1 1/2 oz (≈ 44 ml)');
    });

    test('localizes common measure units and phrases', () {
      expect(localizedMeasure('2 tsp'), '2 colheres de chá (≈ 10 ml)');
      expect(localizedMeasure('to taste'), 'a gosto');
      expect(localizedMeasure('1 ml'), '1 ml');
    });

    test('leaves unrecognized measures unchanged', () {
      expect(localizedMeasure('a splash'), 'a splash');
      expect(localizedMeasure(null), '—');
    });
  });

  test('localizes known drink categories', () {
    expect(localizedDrinkCategory('Ordinary_Drink'), 'Drink comum');
    expect(localizedDrinkCategory('Cocktail'), 'Coquetel');
    expect(localizedDrinkCategory('Custom'), 'Custom');
  });
}
