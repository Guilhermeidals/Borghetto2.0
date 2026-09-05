import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_navigation.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          navigationShell.goBranch(0, initialLocation: true);
        }
      },
      child: Scaffold(
        extendBody: false,
        body: navigationShell,
        bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
      ),
    );
  }
}
