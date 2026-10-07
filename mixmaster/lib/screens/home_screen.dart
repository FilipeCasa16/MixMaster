import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/cocktail_api.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/drink_cards.dart';
import '../widgets/ingredient_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Drink> _drinks = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  int _token = 0;
  List<String> _lastIngredients = [];

  bool get _isRandom =>
      _search.text.trim().isEmpty && appState.filterIngredients.isEmpty;

  @override
  void initState() {
    super.initState();
    _lastIngredients = List.of(appState.filterIngredients);
    appState.addListener(_onAppState);
    _load();
  }

  @override
  void dispose() {
    appState.removeListener(_onAppState);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onAppState() {
    if (!mounted) return;
    if (!listEquals(_lastIngredients, appState.filterIngredients)) {
      _lastIngredients = List.of(appState.filterIngredients);
      _load();
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _load);
  }

  Future<void> _load() async {
    final token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
      _moreError = null;
    });
    try {
      final q = _search.text.trim();
      final ings = List<String>.from(appState.filterIngredients);
      List<Drink> result;
      if (q.isEmpty && ings.isEmpty) {
        result = await CocktailApi.randomDrinks(12);
      } else {
        List<Drink>? bySearch;
        List<Drink>? byIng;
        if (q.isNotEmpty) {
          bySearch = await CocktailApi.searchByName(q);
        }
        if (ings.isNotEmpty) {
          byIng = await CocktailApi.filterByIngredients(ings);
        }
        if (bySearch != null && byIng != null) {
          final ids = byIng.map((d) => d.id).toSet();
          result = bySearch.where((d) => ids.contains(d.id)).toList();
        } else {
          result = bySearch ?? byIng ?? [];
        }
      }
      if (!mounted || token != _token) return;
      setState(() {
        _drinks = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _token) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar os drinks.\nVerifique sua conexão.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final token = _token;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final more = await CocktailApi.randomDrinks(
        8,
        exclude: _drinks.map((d) => d.id).toSet(),
      );
      if (!mounted || token != _token || !_isRandom) return;
      setState(() => _drinks = [..._drinks, ...more]);
    } catch (_) {
      if (mounted) {
        setState(() => _moreError = 'Não foi possível carregar mais drinks.');
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openFilter() async {
    final result = await showIngredientFilterSheet(
      context,
      appState.filterIngredients,
    );
    if (result != null) appState.setIngredients(result);
  }

  /// Alterna blocos de 4 cards grandes (grade 2x2) e faixas horizontais de
  /// cards pequenos para dar ritmo à lista.
  List<Widget> _buildBlocks() {
    final widgets = <Widget>[];
    var i = 0;
    var big = true;
    while (i < _drinks.length) {
      final chunk = _drinks.skip(i).take(big ? 4 : 8).toList();
      i += chunk.length;
      if (big) {
        for (var r = 0; r < chunk.length; r += 2) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: BigDrinkCard(chunk[r])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: r + 1 < chunk.length
                        ? BigDrinkCard(chunk[r + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        for (var rowStart = 0; rowStart < 2; rowStart++) {
          final rowDrinks = chunk.skip(rowStart * 4).take(4).toList();
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 112,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth * 0.54)
                        .clamp(220.0, 350.0)
                        .toDouble();
                    return Stack(
                      children: [
                        ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 48),
                          itemCount: rowDrinks.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, index) => SizedBox(
                            width: cardWidth,
                            child: SmallDrinkCard(rowDrinks[index]),
                          ),
                        ),
                        Positioned(
                          top: 38,
                          right: 4,
                          child: IgnorePointer(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.bg.withAlpha(230),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }
      }
      big = !big;
    }
    return widgets;
  }

  Widget _searchRow() {
    final count = appState.filterIngredients.length;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _load(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar drinks pelo nome...',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                        _load();
                      },
                    ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openFilter,
          child: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: AppColors.accent,
            textColor: Colors.black,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: count > 0
                    ? AppColors.accent.withAlpha(40)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: count > 0 ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: count > 0 ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectedChips() {
    final ings = appState.filterIngredients;
    if (ings.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in ings)
            InputChip(
              label: Text(n),
              avatar: IngredientImage(n, size: 20),
              onDeleted: () =>
                  appState.setIngredients(ings.where((e) => e != n).toList()),
              backgroundColor: AppColors.accent.withAlpha(40),
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(
                  'assets/images/mixmaster-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Text(
                  'MixMaster',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 20),
          _searchRow(),
          ListenableBuilder(
            listenable: appState,
            builder: (_, _) => _selectedChips(),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRandom
                    ? 'Drinks Aleatórios'
                    : 'Resultados${_loading ? '' : ' (${_drinks.length})'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else if (_drinks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'Nenhum drink encontrado.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ..._buildBlocks(),
          if (_isRandom && !_loading && _error == null) ...[
            const SizedBox(height: 8),
            if (_moreError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _moreError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(_loadingMore ? 'Carregando...' : 'Ver mais'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
