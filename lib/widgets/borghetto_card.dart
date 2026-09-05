import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BorghettoCard extends StatelessWidget {
  const BorghettoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.dark = false,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dark;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? AppTheme.forest : AppTheme.surfaceLight,
        borderRadius: AppTheme.radiusLarge,
        border: Border.all(
          color: borderColor ??
              (dark ? AppTheme.sand.withAlpha(34) : AppTheme.outlineLight),
        ),
        boxShadow: dark ? null : AppTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.radiusLarge,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
