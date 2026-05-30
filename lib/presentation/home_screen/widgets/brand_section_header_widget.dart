import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

// Anatomy locked: large bold text left + circular arrow button right (per skeleton)
class BrandSectionHeaderWidget extends StatelessWidget {
  final String brandName;
  final VoidCallback onViewAll;

  const BrandSectionHeaderWidget({
    super.key,
    required this.brandName,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          brandName,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
            letterSpacing: -0.5,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outlineLight, width: 1.5),
              color: AppTheme.surfaceLight,
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_outward_rounded,
                size: 18,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
