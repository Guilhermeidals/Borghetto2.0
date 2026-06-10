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
      CurvedAnimation(
        parent: _arcController,
        curve: Curves.easeOutCubic,
      ),
    );

    _arcController.forward();
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  int get _safeNextRewardPoints {
    if (widget.nextRewardPoints <= 0) {
      return 100;
    }

    return widget.nextRewardPoints;
  }

  int get _remainingPoints {
    final remaining = _safeNextRewardPoints - widget.points;

    if (remaining <= 0) {
      return 0;
    }

    return remaining;
  }

  double get _progress {
    if (_safeNextRewardPoints <= 0) {
      return 0.0;
    }

    return (widget.points / _safeNextRewardPoints).clamp(0.0, 1.0);
  }

  String get _formattedPoints {
    return widget.points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }

  BadgeStatus get _tierBadge {
    final tier = widget.tier.toLowerCase().trim();

    if (tier.contains('gold') || tier.contains('ouro')) {
      return BadgeStatus.gold;
    }

    if (tier.contains('silver') || tier.contains('prata')) {
      return BadgeStatus.silver;
    }

    return BadgeStatus.bronze;
  }

  String get _tierLabel {
    final tier = widget.tier.trim();

    if (tier.isEmpty) {
      return 'Cliente Borghetto';
    }

    final lowerTier = tier.toLowerCase();

    if (lowerTier == 'gold') {
      return 'Cliente Ouro';
    }

    if (lowerTier == 'silver') {
      return 'Cliente Prata';
    }

    if (lowerTier == 'bronze') {
      return 'Cliente Borghetto';
    }

    return tier;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadgeWidget(
                    label: _tierLabel,
                    status: _tierBadge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formattedPoints,
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pontos disponíveis',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _remainingPoints == 0
                        ? 'Benefício disponível'
                        : 'Faltam $_remainingPoints pontos para o próximo benefício',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _arcAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progress * _arcAnimation.value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withAlpha(38),
                          valueColor: const AlwaysStoppedAnimation<Color>(
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
                            ),
                          ),
                          Text(
                            'do clube',
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
  bool shouldRepaint(_ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}