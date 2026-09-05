import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../theme/app_theme.dart';

class DoorUnlockFabWidget extends StatefulWidget {
  const DoorUnlockFabWidget({super.key});

  @override
  State<DoorUnlockFabWidget> createState() => _DoorUnlockFabWidgetState();
}

class _DoorUnlockFabWidgetState extends State<DoorUnlockFabWidget>
    with SingleTickerProviderStateMixin {
  bool _isUnlocking = false;
  bool _isUnlocked = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_isUnlocking) return;

    setState(() => _isUnlocking = true);
    _pulseController.repeat(reverse: true);

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
        backgroundColor: Colors.green.shade700,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      await Future.delayed(const Duration(seconds: 3));

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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isUnlocking ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _handleUnlock,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _isUnlocked ? Colors.green.shade700 : AppTheme.darkText,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (_isUnlocked
                            ? Colors.green.shade700
                            : AppTheme.darkText)
                        .withAlpha(77),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUnlocking)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      _isUnlocked
                          ? Icons.lock_open_rounded
                          : Icons.door_front_door_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isUnlocking
                        ? 'Liberando...'
                        : _isUnlocked
                            ? 'Porta Aberta'
                            : 'Liberar Porta',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
