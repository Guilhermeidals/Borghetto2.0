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
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 12 : 24,
            isTablet ? 12 : 24,
            isTablet ? 12 : 24,
            isTablet ? 12 : 0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 520 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: widget.showForm
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandLockup(isTablet: isTablet),
                  SizedBox(height: isTablet ? 28 : 26),
                  _buildBrandFeature(isTablet: isTablet),
                  SizedBox(height: isTablet ? 28 : 26),
                  if (!widget.showForm) _buildTaglineAndCta(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLockup({required bool isTablet}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Borghetto',
          style: GoogleFonts.outfit(
            fontSize: isTablet ? 70 : 64,
            fontWeight: FontWeight.w900,
            color: AppTheme.darkText,
            height: 0.92,
            letterSpacing: -2.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Mercado e bistrô',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: isTablet ? 34 : 31,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                  height: 0.95,
                  letterSpacing: -1.8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
                  fontSize: 13,
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

  Widget _buildBrandFeature({required bool isTablet}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 22 : 20),
      decoration: BoxDecoration(
        color: AppTheme.forest,
        borderRadius: AppTheme.radiusExtraLarge,
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -76,
            child: Text(
              'B',
              style: GoogleFonts.outfit(
                fontSize: isTablet ? 220 : 190,
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppTheme.sand.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 16,
            child: _SparkIcon(
              size: isTablet ? 42 : 36,
              color: AppTheme.sand.withAlpha(150),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconBadge(),
              const SizedBox(height: 18),
              Text(
                'O sabor de um novo dia.',
                style: GoogleFonts.outfit(
                  fontSize: isTablet ? 29 : 27,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.lightText,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Acesso ao clube, carteirinha digital e entrada facilitada em uma experiência feita para ser leve, próxima e acolhedora.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.sand.withAlpha(220),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _FeaturePill(
                    icon: Icons.local_cafe_rounded,
                    label: 'Bistrô',
                  ),
                  _FeaturePill(
                    icon: Icons.storefront_rounded,
                    label: 'Mercado',
                  ),
                  _FeaturePill(
                    icon: Icons.lock_open_rounded,
                    label: 'Acesso',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBadge() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.sand,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              'B',
              style: GoogleFonts.outfit(
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppTheme.forest,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                size: 15,
                color: AppTheme.sand.withAlpha(230),
              ),
              const SizedBox(width: 6),
              Text(
                'Novo dia',
                style: GoogleFonts.outfit(
                  fontSize: 12,
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

  Widget _buildTaglineAndCta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clube exclusivo Borghetto',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.forest,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Entre, acompanhe seus dados e acesse a loja com praticidade.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedText,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.radiusPill,
              ),
              elevation: 0,
            ),
            child: Text(
              'Começar',
              style: GoogleFonts.outfit(
                fontSize: 14,
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
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
            size: 15,
            color: AppTheme.sand,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
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