import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'ingredients_screen.dart';
import 'lottery_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: appState.tab,
            children: const [
              HomeScreen(),
              IngredientsScreen(),
              LotteryScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: BottomNavigationBar(
              currentIndex: appState.tab,
              onTap: appState.setTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.card,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.muted,
              selectedFontSize: 13,
              unselectedFontSize: 13,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.sports_bar_outlined),
                    activeIcon: Icon(Icons.sports_bar),
                    label: 'Ingredientes'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.help_outline_rounded),
                    activeIcon: Icon(Icons.help_rounded),
                    label: 'Sorteio'),
              ],
            ),
          ),
        );
      },
    );
  }
}
