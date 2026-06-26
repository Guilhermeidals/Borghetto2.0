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

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isTablet = width >= 600;
    final isCompactHeight = height < 720;

    final horizontalPadding = isTablet ? 10.0 : 24.0;
    final topPadding = isTablet ? 8.0 : 24.0;
    final bottomPadding = isTablet ? 8.0 : 0.0;

    final availableHeight = height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        topPadding -
        bottomPadding;

    final contentWidth = isTablet ? 520.0 : width - (horizontalPadding * 2);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: double.infinity,
              height: availableHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandLockup(
                        isTablet: isTablet,
                        isCompactHeight: isCompactHeight,
                      ),
                      SizedBox(
                        height: isCompactHeight ? 14 : (isTablet ? 28 : 26),
                      ),
                      _buildBrandFeature(
                        isTablet: isTablet,
                        isCompactHeight: isCompactHeight,
                      ),
                      if (!widget.showForm) ...[
                        SizedBox(
                          height: isCompactHeight ? 14 : (isTablet ? 28 : 26),
                        ),
                        _buildTaglineAndCta(
                          isCompactHeight: isCompactHeight,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLockup({
    required bool isTablet,
    required bool isCompactHeight,
  }) {
    final titleSize = isCompactHeight ? 52.0 : (isTablet ? 70.0 : 64.0);
    final subtitleSize = isCompactHeight ? 25.0 : (isTablet ? 34.0 : 31.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Borghetto',
          style: GoogleFonts.outfit(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            color: AppTheme.darkText,
            height: 0.92,
            letterSpacing: -2.3,
          ),
        ),
        SizedBox(height: isCompactHeight ? 3 : 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Mercado e bistrô',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                  height: 0.95,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            SizedBox(width: isCompactHeight ? 7 : 10),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactHeight ? 10 : 13,
                vertical: isCompactHeight ? 5 : 7,
              ),
              decoration: BoxDecoration(
                color: AppTheme.caramel,
                borderRadius: AppTheme.radiusPill,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.caramel.withAlpha(45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Clube',
                style: GoogleFonts.outfit(
                  fontSize: isCompactHeight ? 11 : 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandFeature({
    required bool isTablet,
    required bool isCompactHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompactHeight ? 15 : (isTablet ? 22 : 20)),
      decoration: BoxDecoration(
        color: AppTheme.forest,
        borderRadius: isCompactHeight
            ? AppTheme.radiusLarge
            : AppTheme.radiusExtraLarge,
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: isCompactHeight ? -34 : -46,
            top: isCompactHeight ? -56 : -76,
            child: Text(
              'B',
              style: GoogleFonts.outfit(
                fontSize: isCompactHeight ? 150 : (isTablet ? 220 : 190),
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppTheme.sand.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            right: isCompactHeight ? 10 : 18,
            top: isCompactHeight ? 10 : 16,
            child: _SparkIcon(
              size: isCompactHeight ? 30 : (isTablet ? 42 : 36),
              color: AppTheme.sand.withAlpha(150),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconBadge(isCompactHeight: isCompactHeight),
              SizedBox(height: isCompactHeight ? 10 : 18),
              Text(
                'O sabor de um novo dia.',
                style: GoogleFonts.outfit(
                  fontSize: isCompactHeight ? 22 : (isTablet ? 29 : 27),
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.lightText,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: isCompactHeight ? 6 : 10),
              Text(
                'Acesso ao clube, carteirinha digital e entrada facilitada em uma experiência feita para ser leve, próxima e acolhedora.',
                maxLines: isCompactHeight ? 1 : 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: isCompactHeight ? 12 : 14,
                  height: isCompactHeight ? 1.25 : 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.sand.withAlpha(220),
                ),
              ),
              SizedBox(height: isCompactHeight ? 12 : 20),
              Wrap(
                spacing: isCompactHeight ? 6 : 8,
                runSpacing: isCompactHeight ? 6 : 8,
                children: [
                  _FeaturePill(
                    icon: Icons.local_cafe_rounded,
                    label: 'Bistrô',
                    compact: isCompactHeight,
                  ),
                  _FeaturePill(
                    icon: Icons.storefront_rounded,
                    label: 'Mercado',
                    compact: isCompactHeight,
                  ),
                  _FeaturePill(
                    icon: Icons.lock_open_rounded,
                    label: 'Acesso',
                    compact: isCompactHeight,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBadge({required bool isCompactHeight}) {
    return Row(
      children: [
        Container(
          width: isCompactHeight ? 40 : 52,
          height: isCompactHeight ? 40 : 52,
          decoration: BoxDecoration(
            color: AppTheme.sand,
            borderRadius: BorderRadius.circular(isCompactHeight ? 14 : 18),
          ),
          child: Center(
            child: Text(
              'B',
              style: GoogleFonts.outfit(
                fontSize: isCompactHeight ? 23 : 28,
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppTheme.forest,
              ),
            ),
          ),
        ),
        SizedBox(width: isCompactHeight ? 8 : 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompactHeight ? 10 : 12,
            vertical: isCompactHeight ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: AppTheme.radiusPill,
            border: Border.all(
              color: AppTheme.sand.withAlpha(42),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wb_sunny_rounded,
                size: isCompactHeight ? 13 : 15,
                color: AppTheme.sand.withAlpha(230),
              ),
              SizedBox(width: isCompactHeight ? 5 : 6),
              Text(
                'Novo dia',
                style: GoogleFonts.outfit(
                  fontSize: isCompactHeight ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaglineAndCta({required bool isCompactHeight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clube exclusivo Borghetto',
          style: GoogleFonts.outfit(
            fontSize: isCompactHeight ? 13 : 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
            height: 1.25,
          ),
        ),
        SizedBox(height: isCompactHeight ? 4 : 6),
        Text(
          'Entre, acompanhe seus dados e acesse a loja com praticidade.',
          maxLines: isCompactHeight ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: isCompactHeight ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedText,
            height: 1.25,
          ),
        ),
        SizedBox(height: isCompactHeight ? 12 : 20),
        SizedBox(
          width: double.infinity,
          height: isCompactHeight ? 46 : 54,
          child: ElevatedButton(
            onPressed: widget.onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forest,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isCompactHeight ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.radiusPill,
              ),
              elevation: 0,
            ),
            child: Text(
              'Começar',
              style: GoogleFonts.outfit(
                fontSize: isCompactHeight ? 13 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: AppTheme.radiusPill,
        border: Border.all(
          color: AppTheme.sand.withAlpha(34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 13 : 15,
            color: AppTheme.sand,
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.sand,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkIcon extends StatelessWidget {
  const _SparkIcon({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SparkIconPainter(color),
    );
  }
}

class _SparkIconPainter extends CustomPainter {
  _SparkIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.50, 0)
      ..cubicTo(w * 0.58, h * 0.32, w * 0.68, h * 0.42, w, h * 0.50)
      ..cubicTo(w * 0.68, h * 0.58, w * 0.58, h * 0.68, w * 0.50, h)
      ..cubicTo(w * 0.42, h * 0.68, w * 0.32, h * 0.58, 0, h * 0.50)
      ..cubicTo(w * 0.32, h * 0.42, w * 0.42, h * 0.32, w * 0.50, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}