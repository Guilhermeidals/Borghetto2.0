import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// V5 — Dot Minimal: small dot below active icon, label animates in/out with AnimatedSize

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? branchIndex; // null = stub tab

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedVisualIndex = 0;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Clube',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Accessos',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      branchIndex: 3,
    ),
  ];

  void _onTap(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) return; // stub — silent ignore
    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync visual index with shell's current branch
    final currentBranch = widget.navigationShell.currentIndex;
    final matchingTab = _tabs.indexWhere((t) => t.branchIndex == currentBranch);
    if (matchingTab != -1 && matchingTab != _selectedVisualIndex) {
      _selectedVisualIndex = matchingTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: AppTheme.outlineLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: 10, bottom: bottomPad > 0 ? 4 : 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == _selectedVisualIndex;
              final isStub = tab.branchIndex == null;

              return GestureDetector(
                onTap: () => _onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: isStub ? 0.4 : 1.0,
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            isActive ? tab.selectedIcon : tab.icon,
                            key: ValueKey(isActive),
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
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
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
