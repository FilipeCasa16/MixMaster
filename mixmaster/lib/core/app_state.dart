import 'package:flutter/foundation.dart';

/// Estado global simples: aba atual, filtro de ingredientes da Home e favoritos.
class AppState extends ChangeNotifier {
  int tab = 0;
  List<String> filterIngredients = [];
  final Set<String> favorites = {};

  void setTab(int i) {
    if (tab == i) return;
    tab = i;
    notifyListeners();
  }

  void setIngredients(List<String> names) {
    filterIngredients = List.of(names);
    notifyListeners();
  }

  /// Usado pelo botão "Ver Drinks com X": leva para a Home já filtrada.
  void showDrinksWithIngredient(String name) {
    filterIngredients = [name];
    tab = 0;
    notifyListeners();
  }

  bool isFavorite(String id) => favorites.contains(id);

  void toggleFavorite(String id) {
    if (!favorites.remove(id)) favorites.add(id);
    notifyListeners();
  }
}

final appState = AppState();
