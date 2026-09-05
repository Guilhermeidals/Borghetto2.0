import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../features/marketing/widgets/marketing_carousel.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/door_unlock_fab_widget.dart';
import './widgets/home_account_alert_widget.dart';
import './widgets/home_app_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthSession? _session;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final savedSession = await ApiClient.instance.getSavedSession();
    if (!mounted) return;

    setState(() => _session = savedSession);

    try {
      final freshSession = await ApiClient.instance.me();
      if (!mounted) return;
      setState(() => _session = freshSession);
    } catch (_) {
      // Mantém a sessão salva caso a atualização falhe.
    }
  }

  Future<void> _refreshHome() async {
    await _loadSession();
    if (!mounted) return;

    setState(() => _refreshVersion++);
  }

  void _openPhotoUpload() {
    context.go(
      AppRoutes.profileScreen,
      extra: {
        'openPhotoPicker': true,
        'openPhotoPickerRequestId': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: ScrollConfiguration(
          behavior: const _HomeScrollBehavior(),
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            color: AppTheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeAppBarWidget(
                    key: ValueKey('home-app-bar-$_refreshVersion'),
                    onAvatarTap: () => context.go(AppRoutes.profileScreen),
                  ),
                ),
                if (_session != null)
                  SliverToBoxAdapter(
                    child: HomeAccountAlertWidget(
                      session: _session!,
                      onSendPhotoPressed: _openPhotoUpload,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _DoorAccessCard(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                SliverToBoxAdapter(
                  child: MarketingCarousel(
                    key: ValueKey('marketing-carousel-$_refreshVersion'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScrollBehavior extends MaterialScrollBehavior {
  const _HomeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _DoorAccessCard extends StatelessWidget {
  const _DoorAccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.forest, AppTheme.forestSoft],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.door_front_door_outlined,
              color: AppTheme.sandLight,
              size: 25,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acesso à loja',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quando estiver na entrada, toque no botão abaixo para liberar a porta.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.sand,
              height: 1.4,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.center,
            child: DoorUnlockFabWidget(),
          ),
        ],
      ),
    );
  }
}
