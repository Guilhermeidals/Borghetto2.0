import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_session.dart';
import '../../../core/app_export.dart';

class HomeAppBarWidget extends StatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAvatarTap;

  const HomeAppBarWidget({
    super.key,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAvatarTap,
  });

  @override
  State<HomeAppBarWidget> createState() => _HomeAppBarWidgetState();
}

class _HomeAppBarWidgetState extends State<HomeAppBarWidget> {
  AuthSession? _session;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    AuthSession? savedSession;

    try {
      savedSession = await ApiClient.instance.getSavedSession();

      if (mounted && savedSession != null) {
        setState(() {
          _session = savedSession;
          _isLoadingSession = false;
        });
      }

      final freshSession = await ApiClient.instance.me();

      if (!mounted) return;

      setState(() {
        _session = freshSession;
        _isLoadingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _session = savedSession;
        _isLoadingSession = false;
      });
    }
  }

  String get _displayName {
    final name = _session?.name.trim();

    if (name == null || name.isEmpty) {
      return 'Cliente Borghetto';
    }

    return name;
  }

  String get _initials {
    final parts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'CB';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String? get _serverPhotoUrl {
    final facialUserId = _session?.controlIdUserId;

    if (facialUserId == null || facialUserId <= 0) {
      return null;
    }

    final url = ApiClient.instance.resolveFileUrl(
      '/facial/users/$facialUserId/face',
    );

    if (url.isEmpty) {
      return null;
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onAvatarTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.outlineLight,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: _buildAvatarContent(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  _isLoadingSession ? 'Carregando...' : _displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onSearchTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.outlineLight,
                  width: 1.5,
                ),
                color: AppTheme.surfaceLight,
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.darkText,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onCartTap,
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.outlineLight,
                      width: 1.5,
                    ),
                    color: AppTheme.surfaceLight,
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'shopping_bag_outlined',
                      color: AppTheme.darkText,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.backgroundLight,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    final photoUrl = _serverPhotoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        semanticLabel: 'Foto de perfil de $_displayName',
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar();
        },
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 42,
      height: 42,
      color: AppTheme.primary,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bom dia 👋';
    }

    if (hour < 18) {
      return 'Boa tarde 👋';
    }

    return 'Boa noite 👋';
  }
}