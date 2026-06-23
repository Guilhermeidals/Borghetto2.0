import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../theme/app_theme.dart';

class DoorAccessWidget extends StatefulWidget {
  const DoorAccessWidget({super.key});

  @override
  State<DoorAccessWidget> createState() => _DoorAccessWidgetState();
}

class _DoorAccessWidgetState extends State<DoorAccessWidget>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  bool _isUnlocking = false;
  bool _isUnlocked = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_isUnlocking) return;

    setState(() => _isUnlocking = true);
    _pulseController.repeat();

    try {
      await ApiClient.instance.openDoor();

      if (!mounted) return;

      _pulseController.stop();
      _pulseController.reset();

      setState(() {
        _isUnlocking = false;
        _isUnlocked = true;
      });

      Fluttertoast.showToast(
        msg: '🔓 Porta liberada com sucesso',
        backgroundColor: AppTheme.accent,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        setState(() => _isUnlocked = false);
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      _pulseController.stop();
      _pulseController.reset();

      setState(() {
        _isUnlocking = false;
        _isUnlocked = false;
      });

      Fluttertoast.showToast(
        msg: error.message,
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (_) {
      if (!mounted) return;

      _pulseController.stop();
      _pulseController.reset();

      setState(() {
        _isUnlocking = false;
        _isUnlocked = false;
      });

      Fluttertoast.showToast(
        msg: 'Erro inesperado ao liberar porta',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isUnlocked
                      ? AppTheme.accentLight
                      : AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _isUnlocked ? Icons.lock_open_rounded : Icons.store_rounded,
                    size: 20,
                    color: _isUnlocked ? AppTheme.accent : AppTheme.darkText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liberar Porta da Loja',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    Text(
                      _isUnlocked
                          ? 'Porta Aberta — entre agora'
                          : 'Pressione para liberar com Face ID',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _isUnlocked
                            ? AppTheme.accent
                            : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Big unlock button with pulse animation
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring
                if (_isUnlocking)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withOpacity(
                              _pulseOpacity.value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Main unlock button
                GestureDetector(
                  onTap: _handleUnlock,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isUnlocked ? AppTheme.accent : AppTheme.darkText,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isUnlocked
                                      ? AppTheme.accent
                                      : AppTheme.darkText)
                                  .withAlpha(64),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isUnlocking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isUnlocked
                                  ? Icons.lock_open_rounded
                                  : Icons.face_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _isUnlocking
                  ? 'Verificando Face ID...'
                  : _isUnlocked
                  ? 'Bem Vindo! A porta está aberta'
                  : 'Toque para liberar a entrada',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _isUnlocked ? AppTheme.accent : AppTheme.mutedText,
                fontWeight: _isUnlocked ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
  