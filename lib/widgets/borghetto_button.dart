import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BorghettoButton extends StatelessWidget {
  const BorghettoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = secondary ? AppTheme.surfaceLight : AppTheme.forest;
    final foregroundColor = secondary ? AppTheme.forest : Colors.white;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          disabledBackgroundColor: AppTheme.forest.withAlpha(120),
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusPill,
            side: secondary
                ? const BorderSide(color: AppTheme.outlineLight)
                : BorderSide.none,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}