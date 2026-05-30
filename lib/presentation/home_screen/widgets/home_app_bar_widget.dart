import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class HomeAppBarWidget extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAvatarTap;

  const HomeAppBarWidget({
    super.key,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // User avatar — circle, left side per skeleton
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outlineLight, width: 1.5),
              ),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl:
                      'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Profile photo of Maya Chen, a young Asian woman with straight black hair',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  'Nome do home_app_bar_widget',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
          // Search icon — right side per skeleton
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outlineLight, width: 1.5),
                color: AppTheme.surfaceLight,
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.darkText,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Cart icon with badge — right side per skeleton
          GestureDetector(
            onTap: onCartTap,
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.outlineLight,
                      width: 1.5,
                    ),
                    color: AppTheme.surfaceLight,
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'shopping_bag_outlined',
                      color: AppTheme.darkText,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.backgroundLight,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia 👋';
    if (hour < 17) return 'Bom noite 👋';
    return 'Boa tarde 👋';
  }
}
