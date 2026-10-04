import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../data/recipe_localization.dart';
import '../screens/drink_detail_screen.dart';
import 'common.dart';

String _drinkRecipeFact(Drink drink) {
  final alcoholLabel = switch (drink.alcoholic?.toLowerCase()) {
    'alcoholic' => 'Alcoólico',
    'non alcoholic' => 'Sem álcool',
    _ => null,
  };
  final ingredientCount = drink.ingredients.length;
  return [
    ?alcoholLabel,
    if (ingredientCount > 0)
      '$ingredientCount ${ingredientCount == 1 ? 'ingrediente' : 'ingredientes'}',
  ].join(' · ');
}

void openDrink(BuildContext context, Drink drink) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DrinkDetailScreen(id: drink.id, initial: drink),
    ),
  );
}

/// Card grande (imagem quadrada em cima, nome e categoria embaixo).
class BigDrinkCard extends StatelessWidget {
  const BigDrinkCard(this.drink, {super.key});
  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openDrink(context, drink),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: NetImage(
                drink.thumbSized('medium'),
                fallback: drink.thumb,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (drink.category != null) ...[
                    const SizedBox(height: 8),
                    Tag(localizedDrinkCategory(drink.category!)),
                  ],
                  if (_drinkRecipeFact(drink).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _drinkRecipeFact(drink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card pequeno horizontal (imagem à esquerda, texto à direita).
class SmallDrinkCard extends StatelessWidget {
  const SmallDrinkCard(this.drink, {super.key});
  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openDrink(context, drink),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 68,
              height: double.infinity,
              child: NetImage(drink.thumbSized('small'), fallback: drink.thumb),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drink.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (drink.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        localizedDrinkCategory(drink.category!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (_drinkRecipeFact(drink).isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        _drinkRecipeFact(drink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
