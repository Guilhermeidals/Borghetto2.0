import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/borghetto_background.dart';
import './widgets/auth_form_widget.dart';
import './widgets/splash_hero_section_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  bool _showForm = false;
  bool _isLogin = true;

  late AnimationController _formSlideController;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();

    _formSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formSlideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _formFadeAnimation = CurvedAnimation(
      parent: _formSlideController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _formSlideController.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    setState(() {
      _showForm = true;
    });

    _formSlideController.forward();
  }

  void _handleAuthSuccess() {
    context.go(AppRoutes.homeScreen);
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: BorghettoBackground(
        padding: EdgeInsets.zero,
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    final height = MediaQuery.of(context).size.height;
    final formHeight = _isLogin ? height * 0.60 : height * 0.84;
    final heroBottom = _showForm ? formHeight - 18 : 0.0;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          top: 0,
          left: 0,
          right: 0,
          bottom: heroBottom,
          child: SplashHeroSectionWidget(
            showForm: _showForm,
            onGetStarted: _handleGetStarted,
          ),
        ),
        if (_showForm)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: formHeight,
            child: FadeTransition(
              opacity: _formFadeAnimation,
              child: SlideTransition(
                position: _formSlideAnimation,
                child: AuthFormWidget(
                  isLogin: _isLogin,
                  onToggleMode: _toggleMode,
                  onAuthSuccess: _handleAuthSuccess,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !_showForm
                ? ConstrainedBox(
                    key: const ValueKey('tablet-hero-only'),
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SplashHeroSectionWidget(
                      showForm: _showForm,
                      onGetStarted: _handleGetStarted,
                    ),
                  )
                : Row(
                    key: const ValueKey('tablet-auth-layout'),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 520),
                          child: SplashHeroSectionWidget(
                            showForm: _showForm,
                            onGetStarted: _handleGetStarted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 34),
                      Expanded(
                        child: FadeTransition(
                          opacity: _formFadeAnimation,
                          child: SlideTransition(
                            position: _formSlideAnimation,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: AuthFormWidget(
                                isLogin: _isLogin,
                                onToggleMode: _toggleMode,
                                onAuthSuccess: _handleAuthSuccess,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}