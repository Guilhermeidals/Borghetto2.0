import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MemberBenefitsWidget extends StatelessWidget {
  const MemberBenefitsWidget({super.key});

  static const List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.local_offer_rounded,
      'title': 'Exclusive Member Prices',
      'subtitle': 'Up to 50% off on 500+ products weekly',
      'color': Color(0xFF4CAF7D),
    },
    {
      'icon': Icons.star_rounded,
      'title': 'Points on Every Purchase',
      'subtitle': 'Earn 1 point per \$1 spent, double on Fridays',
      'color': Color(0xFFE8A020),
    },
    {
      'icon': Icons.card_giftcard_rounded,
      'title': 'Reward Redemptions',
      'subtitle': 'Redeem 100 pts = \$1 off your next shop',
      'color': Color(0xFF7C4DFF),
    },
    {
      'icon': Icons.door_front_door_rounded,
      'title': 'Express Store Entry',
      'subtitle': 'Skip the queue with Face ID door access',
      'color': Color(0xFF1A1A1A),
    },
    {
      'icon': Icons.notifications_rounded,
      'title': 'Early Access Alerts',
      'subtitle': 'First to know about flash deals & new arrivals',
      'color': Color(0xFFD94040),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Member Benefits',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_benefits.length, (i) {
          final benefit = _benefits[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i < _benefits.length - 1 ? 8 : 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (benefit['color'] as Color).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        benefit['icon'] as IconData,
                        size: 20,
                        color: benefit['color'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          benefit['subtitle'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
