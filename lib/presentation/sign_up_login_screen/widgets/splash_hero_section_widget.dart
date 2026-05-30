import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class SplashHeroSectionWidget extends StatefulWidget {
  final bool showForm;
  final VoidCallback onGetStarted;

  const SplashHeroSectionWidget({
    super.key,
    required this.showForm,
    required this.onGetStarted,
  });

  @override
  State<SplashHeroSectionWidget> createState() =>
      _SplashHeroSectionWidgetState();
}

class _SplashHeroSectionWidgetState extends State<SplashHeroSectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Oversized hero text — crops at right edge per skeleton
              _buildHeroText(),
              const SizedBox(height: 20),
              // Image collage + circular badge
              _buildImageCollage(),
              const SizedBox(height: 24),
              // Tagline + CTA (hidden when form is shown)
              if (!widget.showForm) _buildTaglineAndCta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Borghetto',
          style: GoogleFonts.outfit(
            fontSize: 72,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
            height: 0.95,
            letterSpacing: -2,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Mercado e bistrô',
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
                height: 0.95,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Clube',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCollage() {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left image tile
          Positioned(
            left: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomImageWidget(
                imageUrl:
                    'https://images.pexels.com/photos/1367242/pexels-photo-1367242.jpeg',
                width: 140,
                height: 180,
                fit: BoxFit.cover,
                semanticLabel:
                    'Person wearing earth-toned outfit with fresh produce in a supermarket setting',
              ),
            ),
          ),
          // Right image tile (offset down slightly)
          Positioned(
            left: 148,
            top: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomImageWidget(
                imageUrl:
                    'https://images.pexels.com/photos/1367242/pexels-photo-1367242.jpeg',
                width: 130,
                height: 150,
                fit: BoxFit.cover,
                semanticLabel:
                    'Fresh colorful fruits and vegetables arranged on a light background',
              ),
            ),
          ),
          // Circular green badge with # symbol
          Positioned(
            left: 108,
            bottom: 12,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.backgroundLight, width: 3),
              ),
              child: const Center(
                child: Text(
                  '#',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaglineAndCta() {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Text(
            'Clube Exclusivo',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Começar',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
