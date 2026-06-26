import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import './widgets/door_unlock_fab_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/points_hero_widget.dart';
import './widgets/home_account_alert_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _clubPoints = 0;
  static const int _nextRewardPoints = 100;
  static const String _clubTier = 'Cliente Borghetto';

  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    AuthSession? session = await ApiClient.instance.getSavedSession();

    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
    });

    try {
      final freshSession = await ApiClient.instance.me();

      if (!mounted) {
        return;
      }

      setState(() {
        _session = freshSession;
      });
    } catch (_) {
      // Mantém a sessão salva caso o /auth/me falhe.
    }
  }

  void _openPhotoUpload() {
    context.go(
      AppRoutes.profileScreen,
      extra: {
        'openPhotoPicker': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeAppBarWidget(
                    onSearchTap: () {},
                    onCartTap: () {},
                    onAvatarTap: () {
                      context.go(AppRoutes.profileScreen);
                    },
                  ),
                ),
                if (_session != null)
                SliverToBoxAdapter(
                  child: HomeAccountAlertWidget(
                    session: _session!,
                    onSendPhotoPressed: _openPhotoUpload,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: PointsHeroWidget(
                      memberName: _clubTier,
                      points: _clubPoints,
                      nextRewardPoints: _nextRewardPoints,
                      tier: _clubTier,
                      onCardTap: () {
                        context.go(AppRoutes.digitalMembershipCardScreen);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _ClubInfoCard(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              right: 24,
              child: DoorUnlockFabWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubInfoCard extends StatelessWidget {
  const _ClubInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clube Borghetto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Acompanhe seus pontos, benefícios e vantagens exclusivas como cliente do Mercado Borghetto.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.mutedText,
              height: 1.35,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ClubMiniInfo(
                  icon: Icons.stars_rounded,
                  title: 'Pontos',
                  value: '0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ClubMiniInfo(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Próximo benefício',
                  value: '100 pts',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClubMiniInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ClubMiniInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.mutedText,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}