import 'package:flutter/foundation.dart';

import '../data/local_database.dart';
import '../data/models.dart';

class AppState extends ChangeNotifier {
  int tab = 0;
  List<String> filterIngredients = [];
  final Set<String> favorites = {};
  List<Drink> favoriteDrinks = [];
  LocalAccount? account;
  bool initialized = false;
  String? initializationError;

  Future<void> initialize() async {
    try {
      final database = LocalDatabase.instance;
      account = await database.getCurrentAccount();
      if (account != null) {
        favoriteDrinks = await database.getFavorites(account!.id);
        favorites
          ..clear()
          ..addAll(favoriteDrinks.map((drink) => drink.id));
      }
      initializationError = null;
    } catch (error) {
      initializationError = 'Não foi possível acessar os dados salvos: $error';
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

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

  Future<void> register(String email, String password) async {
    final newAccount = await LocalDatabase.instance.register(email, password);
    await _activateAccount(newAccount);
  }

  Future<void> login(String email, String password) async {
    final loggedInAccount = await LocalDatabase.instance.login(email, password);
    await _activateAccount(loggedInAccount);
  }

  Future<void> _activateAccount(LocalAccount newAccount) async {
    final drinks = await LocalDatabase.instance.getFavorites(newAccount.id);
    account = newAccount;
    favoriteDrinks = drinks;
    favorites
      ..clear()
      ..addAll(drinks.map((drink) => drink.id));
    notifyListeners();
  }

  Future<void> logout() async {
    await LocalDatabase.instance.logout();
    account = null;
    favoriteDrinks = [];
    favorites.clear();
    notifyListeners();
  }

  Future<void> toggleFavorite(Drink drink) async {
    final currentAccount = account;
    if (currentAccount == null) {
      throw const AccountException(
        'Entre na sua conta para salvar drinks favoritos.',
      );
    }
    final shouldFavorite = !favorites.contains(drink.id);
    _updateFavoriteState(drink, shouldFavorite);
    notifyListeners();

    try {
      await LocalDatabase.instance.setFavorite(
        currentAccount.id,
        drink,
        shouldFavorite,
      );
    } catch (_) {
      if (account?.id == currentAccount.id &&
          favorites.contains(drink.id) == shouldFavorite) {
        _updateFavoriteState(drink, !shouldFavorite);
        notifyListeners();
      }
      rethrow;
    }
  }

  void _updateFavoriteState(Drink drink, bool isFavorite) {
    if (isFavorite) {
      favorites.add(drink.id);
      favoriteDrinks = [
        drink,
        ...favoriteDrinks.where((favorite) => favorite.id != drink.id),
      ];
    } else {
      favorites.remove(drink.id);
      favoriteDrinks = favoriteDrinks
          .where((favorite) => favorite.id != drink.id)
          .toList();
    }
  }
}

final appState = AppState();
