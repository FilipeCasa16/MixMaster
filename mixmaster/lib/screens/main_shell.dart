import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'ingredients_screen.dart';
import 'login_screen.dart';
import 'lottery_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    unawaited(appState.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          body: !appState.initialized
              ? const Center(child: CircularProgressIndicator())
              : appState.initializationError != null
                  ? _DatabaseError(
                      message: appState.initializationError!,
                      onRetry: () => unawaited(appState.initialize()),
                    )
                  : IndexedStack(
                      index: appState.tab,
                      children: [
                        const HomeScreen(),
                        const IngredientsScreen(),
                        const LotteryScreen(),
                        appState.account == null
                            ? const LoginScreen()
                            : const AccountScreen(),
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
                BottomNavigationBarItem(
                    icon: Icon(Icons.account_circle_outlined),
                    activeIcon: Icon(Icons.account_circle_rounded),
                    label: 'Conta'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DatabaseError extends StatelessWidget {
  const _DatabaseError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storage_rounded,
                color: AppColors.red,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
}
