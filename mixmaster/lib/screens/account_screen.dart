import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/local_database.dart';
import '../data/models.dart';
import '../data/recipe_localization.dart';
import '../widgets/common.dart';
import '../widgets/drink_cards.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final account = appState.account;
          if (account == null) return const SizedBox.shrink();
          return _buildAccount(context, account, appState.favoriteDrinks);
        },
      );

  Widget _buildAccount(
    BuildContext context,
    LocalAccount account,
    List<Drink> drinks,
  ) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Minha conta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Seu perfil e sua coleção no MixMaster',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.accent.withAlpha(30),
                          foregroundColor: AppColors.accent,
                          child: Text(
                            account.displayName.isEmpty
                                ? '?'
                                : account.displayName[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.displayName.isEmpty
                                    ? 'Minha conta'
                                    : account.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                account.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _logoutButton(context),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Drinks curtidos',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${drinks.length} ${drinks.length == 1 ? 'drink' : 'drinks'}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (drinks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyFavorites(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.sizeOf(context).width;
                  final textScale = MediaQuery.textScalerOf(context).scale(14);
                  final cardHeight = 150 + textScale * 3.5;
                  return SliverGrid.builder(
                    itemCount: drinks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width < 340 ? 1 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: cardHeight,
                    ),
                    itemBuilder: (context, index) =>
                        _FavoriteDrinkCard(drink: drinks[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          try {
            await appState.logout();
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Não foi possível sair da conta. Tente novamente.'),
                ),
              );
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sair da conta',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _FavoriteDrinkCard extends StatelessWidget {
  const _FavoriteDrinkCard({required this.drink});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(drink.thumbSized('medium'), fallback: drink.thumb),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AppColors.card.withAlpha(230),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remover dos favoritos',
                        onPressed: () async {
                          try {
                            await appState.toggleFavorite(drink);
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error is AccountException
                                        ? error.message
                                        : 'Não foi possível atualizar os favoritos.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (drink.category != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      localizedDrinkCategory(drink.category!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
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

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                size: 42,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sua coleção ainda está vazia',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toque no coração de um drink para salvá-lo aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => appState.setTab(0),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explorar drinks'),
              ),
            ],
          ),
        ),
      );
}
