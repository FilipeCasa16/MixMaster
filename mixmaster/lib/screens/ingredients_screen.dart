import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/cocktail_api.dart';
import '../data/models.dart';
import '../data/translation_service.dart';
import '../widgets/common.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final _query = TextEditingController();
  List<String> _all = [];
  List<String> _remoteMatches = [];
  bool _loading = true;
  String? _error;
  String? _searchError;
  Timer? _searchDebounce;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final names = await CocktailApi.ingredientNames();
      if (!mounted) return;
      setState(() {
        _all = names;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar os ingredientes.';
      });
    }
  }

  void _openDetails(String name) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _IngredientDialog(name: name),
    );
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _searchDebounce?.cancel();
    final token = ++_searchToken;
    setState(() {
      _remoteMatches = [];
      _searchError = null;
    });
    if (query.length < 2) return;

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final matches = await CocktailApi.searchIngredientNames(query);
        if (!mounted || token != _searchToken) return;
        setState(() => _remoteMatches = matches);
      } catch (_) {
        if (!mounted || token != _searchToken) return;
        setState(
          () => _searchError =
              'Não foi possível consultar ingredientes fora da lista inicial.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final shown =
        q.isEmpty
              ? _all
              : {
                  ..._all.where((n) => n.toLowerCase().contains(q)),
                  ..._remoteMatches,
                }.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingredientes',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Busque e explore a base de insumos',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _query,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Filtrar ingredientes...',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
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
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: ErrorView(message: _error!, onRetry: _load),
                    )
                  : shown.isEmpty
                  ? Center(
                      child: Text(
                        _searchError ?? 'Nenhum ingrediente encontrado.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  : Column(
                      children: [
                        if (_searchError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _searchError!,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 78,
                                ),
                            itemCount: shown.length,
                            itemBuilder: (_, i) => _IngredientCard(
                              name: shown[i],
                              onTap: () => _openDetails(shown[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IngredientImage(name, size: 52, circle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  IngredientTypeText(name),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientDialog extends StatelessWidget {
  const _IngredientDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: FutureBuilder<Ingredient?>(
            future: CocktailApi.ingredientDetails(name),
            builder: (context, snap) {
              final ing = snap.data;
              final loading = snap.connectionState != ConnectionState.done;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DETALHES DO INGREDIENTE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  IngredientImage(
                    name,
                    size: 150,
                    circle: true,
                    imageSize: 'Medium',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    if (snap.hasError)
                      const Text(
                        'Não foi possível carregar os detalhes do ingrediente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    if (ing != null)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          Tag(ing.label),
                          if (ing.alcohol != null)
                            Tag(
                              ing.isAlcoholic ? 'Alcoólico' : 'Não alcoólico',
                              color: ing.isAlcoholic
                                  ? AppColors.red
                                  : AppColors.green,
                            ),
                        ],
                      ),
                    if (ing?.description != null &&
                        ing!.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FutureBuilder<String>(
                        future: TranslationService.translateText(
                          ing.description!.trim(),
                        ),
                        builder: (context, translation) => Column(
                          children: [
                            if (translation.connectionState !=
                                ConnectionState.done)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Traduzindo descrição...',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 12),
                                ),
                              ),
                            if (translation.hasError)
                              const Text(
                                'Tradução indisponível; descrição original em inglês.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              translation.data ?? ing.description!.trim(),
                              textAlign: TextAlign.center,
                              maxLines: 8,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        appState.showDrinksWithIngredient(name);
                      },
                      child: Text(
                        'Ver Drinks com $name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
