import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PointsSummaryRowWidget extends StatelessWidget {
  final int points;
  final int redeemable;
  final int thisMonth;

  const PointsSummaryRowWidget({
    super.key,
    required this.points,
    required this.redeemable,
    required this.thisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              label: 'Total Points',
              value: _formatNumber(points),
              color: AppTheme.darkText,
            ),
          ),
          _divider(),
          Expanded(
            child: _summaryItem(
              label: 'Redeemable',
              value: _formatNumber(redeemable),
              color: AppTheme.accent,
            ),
          ),
          _divider(),
          Expanded(
            child: _summaryItem(
              label: 'This Month',
              value: '+${_formatNumber(thisMonth)}',
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.mutedText),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: AppTheme.outlineLight);
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
