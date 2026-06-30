import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_navigation.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({required this.navigationShell, super.key});

  Future<bool> _handleBackButton() async {
    final isOnHome = navigationShell.currentIndex == 0;

    if (!isOnHome) {
      navigationShell.goBranch(
        0,
        initialLocation: true,
      );

      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        extendBody: false,
        body: navigationShell,
        bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
      ),
    );
  }
}