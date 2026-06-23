import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BorghettoBackground extends StatelessWidget {
  const BorghettoBackground({
    super.key,
    required this.child,
    this.dark = false,
    this.padding,
  });

  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final watermarkColor = dark
        ? AppTheme.sand.withAlpha(14)
        : AppTheme.forest.withAlpha(18);

    return Container(
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.forestGradient : AppTheme.morningGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _SoftOrb(
              size: 220,
              color: dark
                  ? AppTheme.sand.withAlpha(16)
                  : AppTheme.caramel.withAlpha(18),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: _SoftOrb(
              size: 240,
              color: dark
                  ? AppTheme.forestSoft.withAlpha(60)
                  : AppTheme.forest.withAlpha(10),
            ),
          ),

          // Marca d'água gigante com o "B"
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: size.height,
                  width: size.width,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        'B',
                        style: GoogleFonts.outfit(
                          fontSize: size.height * 0.95,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: watermarkColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}