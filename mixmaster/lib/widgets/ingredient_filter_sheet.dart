import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/cocktail_api.dart';

/// Abre o filtro de ingredientes da Home e devolve a lista escolhida
/// (ou null se o usuário fechar sem aplicar).
Future<List<String>?> showIngredientFilterSheet(
  BuildContext context,
  List<String> current,
) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final List<String> initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _selected = {...widget.initial};
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
        setState(() => _searchError =
            'Não foi possível consultar ingredientes fora da lista inicial.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final shown = q.isEmpty
        ? _all
        : {
            ..._all.where((n) => n.toLowerCase().contains(q)),
            ..._remoteMatches,
          }.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final height = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtrar por ingredientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Mostra drinks que levam todos os ingredientes marcados',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 14),
              TextField(
                controller: _query,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar ingrediente...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _selected)
                      InputChip(
                        label: Text(s),
                        onDeleted: () => setState(() => _selected.remove(s)),
                        backgroundColor: AppColors.accent.withAlpha(40),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: TextButton(
                              onPressed: _load,
                              child: Text('$_error Toque para tentar de novo.'),
                            ),
                          )
                        : ListView.builder(
                            itemCount: shown.length + (_searchError == null ? 0 : 1),
                            itemBuilder: (_, i) {
                              if (i >= shown.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _searchError!,
                                    style: const TextStyle(
                                        color: AppColors.muted),
                                  ),
                                );
                              }
                              final n = shown[i];
                              return CheckboxListTile(
                                value: _selected.contains(n),
                                title: Text(n),
                                activeColor: AppColors.accent,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(n);
                                  } else {
                                    _selected.remove(n);
                                  }
                                }),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(_selected.clear),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () =>
                          Navigator.pop(context, _selected.toList()),
                      child: Text(
                        _selected.isEmpty
                            ? 'Aplicar'
                            : 'Aplicar (${_selected.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
