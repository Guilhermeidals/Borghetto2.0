import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class PointsHeroWidget extends StatefulWidget {
  final String memberName;
  final int points;
  final int nextRewardPoints;
  final String tier;
  final VoidCallback onCardTap;

  const PointsHeroWidget({
    super.key,
    required this.memberName,
    required this.points,
    required this.nextRewardPoints,
    required this.tier,
    required this.onCardTap,
  });

  @override
  State<PointsHeroWidget> createState() => _PointsHeroWidgetState();
}

class _PointsHeroWidgetState extends State<PointsHeroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcController;
  late Animation<double> _arcAnimation;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _arcAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _arcController, curve: Curves.easeOutCubic),
    );
    _arcController.forward();
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  double get _progress =>
      (widget.points / widget.nextRewardPoints).clamp(0.0, 1.0);

  BadgeStatus get _tierBadge {
    switch (widget.tier.toLowerCase()) {
      case 'gold':
        return BadgeStatus.gold;
      case 'silver':
        return BadgeStatus.silver;
      default:
        return BadgeStatus.bronze;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCardTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkText,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Left: text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadgeWidget(
                    label: '${widget.tier} Member',
                    status: _tierBadge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'loyalty points',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.nextRewardPoints - widget.points} pts to next reward',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _arcAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progress * _arcAnimation.value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withAlpha(38),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accent,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Right: radial arc progress
            AnimatedBuilder(
              animation: _arcAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 88,
                  height: 88,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      progress: _progress * _arcAnimation.value,
                      trackColor: Colors.white.withAlpha(31),
                      progressColor: AppTheme.accent,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            'to tier',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.white.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
