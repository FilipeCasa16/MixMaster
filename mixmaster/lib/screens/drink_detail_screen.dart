import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/cocktail_api.dart';
import '../data/models.dart';
import '../data/recipe_localization.dart';
import '../data/translation_service.dart';
import '../widgets/common.dart';

class DrinkDetailScreen extends StatefulWidget {
  const DrinkDetailScreen({super.key, required this.id, this.initial});
  final String id;
  final Drink? initial;

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  late Future<Drink?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final init = widget.initial;
    _future = (init != null && init.detailed)
        ? Future.value(init)
        : CocktailApi.lookup(widget.id);
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xCC0B0B0F),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Drink?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Stack(
              children: [
                const Center(child: CircularProgressIndicator()),
                _topBar(null),
              ],
            );
          }
          final drink = snap.data;
          if (snap.hasError || drink == null) {
            return Stack(
              children: [
                Center(
                  child: ErrorView(
                    message: 'Não foi possível carregar este drink.',
                    onRetry: () => setState(_load),
                  ),
                ),
                _topBar(null),
              ],
            );
          }
          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 380,
                    child: NetImage(drink.thumb),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: _body(drink),
                  ),
                ],
              ),
              _topBar(drink),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar(Drink? drink) {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleButton(
                  Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
              if (drink != null)
                ListenableBuilder(
                  listenable: appState,
                  builder: (_, __) {
                    final fav = appState.isFavorite(drink.id);
                    return _circleButton(
                      fav ? Icons.favorite : Icons.favorite_border,
                      () => appState.toggleFavorite(drink.id),
                      color: fav ? AppColors.red : Colors.white,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Drink d) {
    return FutureBuilder<LocalizedDrink>(
      future: TranslationService.translateDrink(d),
      builder: (context, snapshot) {
        final localized = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const _TranslationNotice(
                  message: 'Traduzindo os detalhes para português...'),
            if (snapshot.hasError)
              const _TranslationNotice(
                  message:
                      'Tradução indisponível; exibindo o conteúdo original em inglês.'),
            _localizedBody(d, localized),
          ],
        );
      },
    );
  }

  Widget _localizedBody(Drink d, LocalizedDrink? localized) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(d.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (d.category != null) Tag(localizedDrinkCategory(d.category!)),
            if (d.alcoholic != null)
              Tag(
                d.alcoholic!.toLowerCase() == 'alcoholic'
                    ? 'Alcoólico'
                    : d.alcoholic!.toLowerCase().contains('non')
                        ? 'Não alcoólico'
                        : d.alcoholic!,
                color: d.alcoholic!.toLowerCase() == 'alcoholic'
                    ? AppColors.red
                    : AppColors.green,
              ),
            if (d.glass != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_bar_outlined,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                      localized?.glass ?? cleanTranslationOutput(d.glass!),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 15)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('Ingredientes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (var index = 0; index < d.ingredients.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                IngredientImage(d.ingredients[index].name, size: 48),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                      localized != null &&
                              index < localized.ingredientNames.length
                          ? localized.ingredientNames[index]
                          : cleanTranslationOutput(
                              d.ingredients[index].name,
                            ),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    localizedMeasure(d.ingredients[index].measure),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (d.instructions != null) ...[
          const SizedBox(height: 18),
          const Text('Modo de Preparo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            localized?.instructions ??
                cleanTranslationOutput(d.instructions!),
            style: const TextStyle(
                color: AppColors.muted, fontSize: 16, height: 1.55),
          ),
        ],
      ],
    );
  }
}

class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
}
