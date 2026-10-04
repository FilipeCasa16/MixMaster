import 'package:flutter_test/flutter_test.dart';
import 'package:mixmaster/data/recipe_localization.dart';
import 'package:mixmaster/data/translation_service.dart';

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

  group('cleanTranslationOutput', () {
    test('removes translation markup without dropping its text', () {
      expect(
        cleanTranslationOutput(
          '<g id="1">aguardente de damasco</g><g id="2"/>',
        ),
        'aguardente de damasco',
      );
    });

    test('also removes escaped markup and decodes text entities', () {
      expect(
        cleanTranslationOutput(
          '&lt;g id=&quot;1&quot;&gt;Agite &amp; coe&lt;/g&gt;',
        ),
        'Agite & coe',
      );
      expect(
        cleanTranslationOutput(
          '&amp;lt;g id=&amp;quot;1&amp;quot;&amp;gt;Limão&amp;lt;/g&amp;gt;',
        ),
        'Limão',
      );
    });

    test('does not show XML id tags or excess whitespace', () {
      final cleaned = cleanTranslationOutput(
        '<g id="1">Limao</g>   <g id="2">siciliano</g>',
      );
      expect(cleaned, 'Limao siciliano');
      expect(cleaned, isNot(contains('<')));
      expect(cleaned, isNot(contains('id=')));
    });
  });
}
