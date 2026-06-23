import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class MemberBenefitsWidget extends StatelessWidget {
  const MemberBenefitsWidget({super.key});

  static const List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.face_retouching_natural_rounded,
      'title': 'Acesso Facial',
      'subtitle': 'Entre no mercado usando seu cadastro facial, sem precisar de cartão.',
      'color': Color(0xFF1A1A1A),
    },
    {
      'icon': Icons.badge_rounded,
      'title': 'Carteirinha Digital',
      'subtitle': 'Tenha seus dados de cliente sempre disponíveis no aplicativo.',
      'color': Color(0xFF4CAF7D),
    },
    {
      'icon': Icons.local_offer_rounded,
      'title': 'Ofertas do Borghetto',
      'subtitle': 'Acompanhe promoções e vantagens exclusivas para clientes cadastrados.',
      'color': Color(0xFFD94040),
    },
    {
      'icon': Icons.star_rounded,
      'title': 'Clube de Pontos',
      'subtitle': 'Em breve, acompanhe pontos e vantagens pelo aplicativo.',
      'color': Color(0xFFE8A020),
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Avisos Importantes',
      'subtitle': 'Receba novidades, comunicados e campanhas especiais do mercado.',
      'color': Color(0xFF7C4DFF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vantagens para Clientes',
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
            padding: EdgeInsets.only(
              bottom: i < _benefits.length - 1 ? 8 : 0,
            ),
            child: _BenefitCard(
              icon: benefit['icon'] as IconData,
              title: benefit['title'] as String,
              subtitle: benefit['subtitle'] as String,
              color: benefit['color'] as Color,
            ),
          );
        }),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.outlineLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}