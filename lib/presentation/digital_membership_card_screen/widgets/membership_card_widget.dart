import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

// Anatomy locked: full-width card, member name + tier + card number + QR + expiry
class MembershipCardWidget extends StatefulWidget {
  final String memberName;
  final String memberId;
  final String tier;
  final String expiryDate;
  final int points;

  const MembershipCardWidget({
    super.key,
    required this.memberName,
    required this.memberId,
    required this.tier,
    required this.expiryDate,
    required this.points,
  });

  @override
  State<MembershipCardWidget> createState() => _MembershipCardWidgetState();
}

class _MembershipCardWidgetState extends State<MembershipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

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
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.darkText,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(10),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withAlpha(31),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: brand + tier badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Borghetto',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        StatusBadgeWidget(
                          label: 'Membro ${widget.tier}',
                          status: _tierBadge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Member name
                    Text(
                      widget.memberName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since May 2024',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withAlpha(128),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Card number row
                    Row(
                      children: [
                        Text(
                          _formatCardNumber(widget.memberId),
                          style: GoogleFonts.outfitTextTheme().bodyMedium
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(204),
                                letterSpacing: 2,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bottom row: QR + expiry + points
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // QR code placeholder (custom drawn)
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomPaint(painter: _QrPatternPainter()),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardInfoRow('Expires', widget.expiryDate),
                              const SizedBox(height: 8),
                              _cardInfoRow(
                                'Points',
                                widget.points.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]},',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white.withAlpha(128),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _formatCardNumber(String id) {
    // Format: SC-2024-00847 → keep as is
    return id;
  }
}

// Simple QR-like pattern painter for visual representation
class _QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.darkText;
    final cell = size.width / 8;

    // Draw a simplified QR pattern
    const pattern = [
      [1, 1, 1, 1, 1, 1, 1, 0],
      [1, 0, 0, 0, 0, 0, 1, 0],
      [1, 0, 1, 1, 1, 0, 1, 0],
      [1, 0, 1, 0, 1, 0, 1, 1],
      [1, 0, 1, 1, 1, 0, 1, 0],
      [1, 0, 0, 0, 0, 0, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 0, 1, 0, 1, 0, 1],
    ];

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell - 0.5, cell - 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPatternPainter oldDelegate) => false;
}
