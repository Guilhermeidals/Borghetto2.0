import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BorghettoScreenHeader extends StatelessWidget {
  const BorghettoScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.light = false,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? AppTheme.lightText : AppTheme.darkText;
    final subtitleColor = light
        ? AppTheme.sand.withAlpha(210)
        : AppTheme.mutedText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 14),
          trailing!,
        ],
      ],
    );
  }
}