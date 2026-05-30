import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BadgeStatus { active, expiring, redeemed, gold, silver, bronze, info }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final BadgeStatus status;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.status,
  });

  Color _bgColor() {
    switch (status) {
      case BadgeStatus.active:
        return AppTheme.accentLight;
      case BadgeStatus.expiring:
        return AppTheme.warningLight;
      case BadgeStatus.redeemed:
        return AppTheme.surfaceVariantLight;
      case BadgeStatus.gold:
        return const Color(0xFFFFF8E1);
      case BadgeStatus.silver:
        return const Color(0xFFF5F5F5);
      case BadgeStatus.bronze:
        return const Color(0xFFFBEEE4);
      case BadgeStatus.info:
        return const Color(0xFFE8F0FE);
    }
  }

  Color _textColor() {
    switch (status) {
      case BadgeStatus.active:
        return AppTheme.success;
      case BadgeStatus.expiring:
        return AppTheme.warning;
      case BadgeStatus.redeemed:
        return AppTheme.mutedText;
      case BadgeStatus.gold:
        return const Color(0xFFB8860B);
      case BadgeStatus.silver:
        return const Color(0xFF6B6B6B);
      case BadgeStatus.bronze:
        return const Color(0xFF8B4513);
      case BadgeStatus.info:
        return const Color(0xFF1A5DC7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor(),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
