import 'package:flutter/material.dart';

import '../../../core/api/auth_session.dart';
import '../../../theme/app_theme.dart';

class HomeAccountAlertWidget extends StatelessWidget {
  const HomeAccountAlertWidget({
    super.key,
    required this.session,
    required this.onSendPhotoPressed,
  });

  final AuthSession session;
  final VoidCallback onSendPhotoPressed;

  bool get _hasPhoto {
    final photoUrl = session.photoUrl?.trim();
    return photoUrl != null && photoUrl.isNotEmpty;
  }

  bool get _needsPhoto {
    return !_hasPhoto;
  }

  @override
  Widget build(BuildContext context) {
    if (session.isApproved && !_needsPhoto) {
      return const SizedBox.shrink();
    }

    if (_needsPhoto) {
      return _StatusCard(
        icon: Icons.camera_alt_rounded,
        title: 'Complete seu cadastro',
        message:
            'Envie sua foto facial para que seu acesso ao mercado possa ser analisado.',
        buttonText: 'Enviar foto',
        onPressed: onSendPhotoPressed,
        tone: _AlertTone.info,
      );
    }

    if (session.isPendingApproval) {
      return const _StatusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Cadastro aguardando aprovação',
        message:
            'Sua foto foi enviada. Aguarde a aprovação de um administrador para liberar o acesso.',
        tone: _AlertTone.warning,
      );
    }

    if (session.isRejected) {
      return const _StatusCard(
        icon: Icons.cancel_rounded,
        title: 'Cadastro não aprovado',
        message:
            'Seu cadastro não foi aprovado. Procure a administração para mais informações.',
        tone: _AlertTone.error,
      );
    }

    if (session.isBlocked) {
      return const _StatusCard(
        icon: Icons.block_rounded,
        title: 'Acesso bloqueado',
        message:
            'Seu acesso está bloqueado. Procure a administração para mais informações.',
        tone: _AlertTone.error,
      );
    }

    return const SizedBox.shrink();
  }
}

enum _AlertTone {
  info,
  warning,
  error,
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    this.buttonText,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final _AlertTone tone;
  final String? buttonText;
  final VoidCallback? onPressed;

  Color get _mainColor {
    switch (tone) {
      case _AlertTone.info:
        return AppTheme.primary;
      case _AlertTone.warning:
        return AppTheme.warning;
      case _AlertTone.error:
        return AppTheme.error;
    }
  }

  Color get _backgroundColor {
    switch (tone) {
      case _AlertTone.info:
        return AppTheme.forestMist;
      case _AlertTone.warning:
        return AppTheme.warningLight;
      case _AlertTone.error:
        return AppTheme.error.withAlpha(18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasButton = buttonText != null && onPressed != null;
    final color = _mainColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(
          color: color.withAlpha(55),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        height: 1.35,
                      ),
                ),
                if (hasButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: onPressed,
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                      ),
                      label: Text(buttonText!),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}