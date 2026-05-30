import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_form_widget.dart';
import './widgets/splash_hero_section_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
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
    _formSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
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
    setState(() => _showForm = true);
    _formSlideController.forward();
  }

  void _handleAuthSuccess() {
    context.go(AppRoutes.homeScreen);
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        // Hero section always visible
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          top: 0,
          left: 0,
          right: 0,
          bottom: _showForm ? MediaQuery.of(context).size.height * 0.55 : 0,
          child: SplashHeroSectionWidget(
            showForm: _showForm,
            onGetStarted: _handleGetStarted,
          ),
        ),
        // Form slides up from bottom
        if (_showForm)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.58,
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
        child: Column(
          children: [
            SplashHeroSectionWidget(
              showForm: _showForm,
              onGetStarted: _handleGetStarted,
            ),
            if (_showForm)
              FadeTransition(
                opacity: _formFadeAnimation,
                child: SlideTransition(
                  position: _formSlideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
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
    );
  }
}
