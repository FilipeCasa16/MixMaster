import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixmaster/core/app_state.dart';
import 'package:mixmaster/data/local_database.dart';
import 'package:mixmaster/data/models.dart';
import 'package:mixmaster/screens/account_screen.dart';

void main() {
  testWidgets('account favorites update when app state changes', (
    tester,
  ) async {
    appState.account = const LocalAccount(id: 1, email: 'drink@example.com');
    appState.favoriteDrinks = [_drink('1', 'First Drink')];
    appState.favorites
      ..clear()
      ..add('1');
    addTearDown(() {
      appState.account = null;
      appState.favoriteDrinks = [];
      appState.favorites.clear();
      appState.notifyListeners();
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AccountScreen())),
    );
    expect(find.text('First Drink'), findsOneWidget);
    expect(find.text('1 drink'), findsOneWidget);

    appState.favoriteDrinks = [_drink('2', 'Second Drink')];
    appState.favorites
      ..clear()
      ..add('2');
    appState.notifyListeners();
    await tester.pump();

    expect(find.text('First Drink'), findsNothing);
    expect(find.text('Second Drink'), findsOneWidget);
    expect(find.text('1 drink'), findsOneWidget);
  });
}

Drink _drink(String id, String name) =>
    Drink(id: id, name: name, category: 'Cocktail');
