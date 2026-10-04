import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/cocktail_api.dart';
import '../data/models.dart';
import 'drink_detail_screen.dart';

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  int _selected = 1; // "Festa!" vem marcado no wireframe
  bool _loading = false;

  Future<void> _draw() async {
    setState(() => _loading = true);
    try {
      final drink = await CocktailApi.drinkForMood(moods[_selected]);
      if (!mounted) return;
      if (drink == null) throw Exception('sem drink');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DrinkDetailScreen(id: drink.id, initial: drink),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sortear agora. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sorteio de Drink 🎲',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Como você está se sentindo hoje?',
                style: TextStyle(color: AppColors.muted, fontSize: 16)),
            const Spacer(),
            for (var i = 0; i < moods.length; i++) _moodTile(i),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _loading ? null : _draw,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Sortear Meu Drink!',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodTile(int i) {
    final m = moods[i];
    final sel = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF241C14) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: sel ? AppColors.accent : AppColors.border,
              width: sel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: sel ? AppColors.accent : Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(m.subtitle,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 15)),
                ],
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle_outline,
                  color: AppColors.accent, size: 30),
          ],
        ),
      ),
    );
  }
}
