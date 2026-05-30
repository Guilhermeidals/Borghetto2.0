import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/status_badge_widget.dart';

// Anatomy locked: image top + name + price (colored) + description (per skeleton)
class OfferCardWidget extends StatelessWidget {
  final Map<String, dynamic> offer;

  const OfferCardWidget({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final isMembersOnly = offer['membersOnly'] as bool;
    final isExpiring = offer['status'] == 'expiring';

    return Container(
      width: 168,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpiring
              ? AppTheme.warning.withAlpha(102)
              : AppTheme.outlineLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image top — aspect ~1:1
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                CustomImageWidget(
                  imageUrl: offer['imageUrl'] as String,
                  width: 168,
                  height: 140,
                  fit: BoxFit.cover,
                  semanticLabel: offer['semanticLabel'] as String,
                ),
                // Discount badge — top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      offer['discount'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Members-only lock badge
                if (isMembersOnly)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content below image
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['name'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '\$${(offer['price'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accent,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\$${(offer['originalPrice'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.mutedText,
                        decoration: TextDecoration.lineThrough,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  offer['description'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isExpiring) ...[
                  const SizedBox(height: 6),
                  StatusBadgeWidget(
                    label: 'Expires soon',
                    status: BadgeStatus.expiring,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
