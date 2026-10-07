import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/cocktail_api.dart';
import '../data/models.dart';

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = AppColors.accent});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(36),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fallback, this.fit = BoxFit.cover});
  final String? url;
  final String? fallback;
  final BoxFit fit;

  Widget _placeholder() => Container(
        color: AppColors.card,
        child: const Center(
          child: Icon(Icons.local_bar_outlined, color: AppColors.muted),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (url == null) return _placeholder();
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (_, _, _) => fallback == null
          ? _placeholder()
          : Image.network(
              fallback!,
              fit: fit,
              errorBuilder: (_, _, _) => _placeholder(),
            ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppColors.card,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
    );
  }
}

class IngredientImage extends StatelessWidget {
  const IngredientImage(this.name,
      {super.key, this.size = 48, this.circle = false, this.imageSize = 'Small'});
  final String name;
  final double size;
  final bool circle;
  final String imageSize;

  @override
  Widget build(BuildContext context) {
    final img = Image.network(
      CocktailApi.ingredientImage(name, size: imageSize),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.liquor, color: AppColors.muted),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: circle ? const Color(0xFF202026) : Colors.transparent,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: img,
    );
  }
}

/// Tag "Bebida / Suco / Tempero" carregada sob demanda a partir da API.
class IngredientTypeText extends StatelessWidget {
  const IngredientTypeText(this.name, {super.key});
  final String name;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Ingredient?>(
      future: CocktailApi.ingredientDetails(name),
      builder: (_, snap) => Text(
        snap.data?.label ?? ' ',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
}
