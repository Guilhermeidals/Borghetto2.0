import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api/api_client.dart';
import '../core/api/auth_session.dart';
import '../theme/app_theme.dart';

// V5 — Dot Minimal: small dot below active icon, label animates in/out with AnimatedSize

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int branchIndex;
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;
  AuthSession? _session;

  bool get _isAdmin => _session?.isAdmin == true;

  List<_TabSpec> get _visibleTabs {
    return [
      const _TabSpec(
        label: 'Início',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        branchIndex: 0,
      ),
      const _TabSpec(
        label: 'Clube',
        icon: Icons.credit_card_outlined,
        selectedIcon: Icons.credit_card_rounded,
        branchIndex: 1,
      ),
      const _TabSpec(
        label: 'Acessos',
        icon: Icons.history_outlined,
        selectedIcon: Icons.history_rounded,
        branchIndex: 2,
      ),
      if (_isAdmin)
        const _TabSpec(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings_rounded,
          branchIndex: 3,
        ),
      const _TabSpec(
        label: 'Perfil',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        branchIndex: 4,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
    _syncSelectedVisualIndex();
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedVisualIndex();
  }

  Future<void> _loadSession() async {
    final session = await ApiClient.instance.getSavedSession();

    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
    });

    _syncSelectedVisualIndex();
  }

  void _syncSelectedVisualIndex() {
    final currentBranch = widget.navigationShell.currentIndex;
    final tabs = _visibleTabs;

    final matchingTab = tabs.indexWhere(
      (tab) => tab.branchIndex == currentBranch,
    );

    if (matchingTab != -1 && matchingTab != _selectedVisualIndex) {
      setState(() {
        _selectedVisualIndex = matchingTab;
      });
    }
  }

  void _onTap(int visualIndex) {
    final tabs = _visibleTabs;

    if (visualIndex < 0 || visualIndex >= tabs.length) {
      return;
    }

    final tab = tabs[visualIndex];

    setState(() {
      _selectedVisualIndex = visualIndex;
    });

    widget.navigationShell.goBranch(
      tab.branchIndex,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final tabs = _visibleTabs;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: const Border(
          top: BorderSide(
            color: AppTheme.outlineLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: bottomPad > 0 ? 4 : 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isActive = index == _selectedVisualIndex;

              return GestureDetector(
                onTap: () => _onTap(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: tabs.length >= 5 ? 58 : 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          isActive ? tab.selectedIcon : tab.icon,
                          key: ValueKey('${tab.label}-$isActive'),
                          size: 24,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: isActive
                            ? Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 4 : 0,
                        height: isActive ? 4 : 0,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}