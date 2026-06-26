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
      _isLogin = true;
      _showForm = true;
    });

    _formSlideController.forward(from: 0);
  }

  void _handleAuthSuccess() {
    context.go(AppRoutes.homeScreen);
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _hideForm() {
    _formSlideController.reverse().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _showForm = false;
        _isLogin = true;
      });
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
    return Stack(
      children: [
        Positioned.fill(
          child: SplashHeroSectionWidget(
            showForm: _showForm,
            onGetStarted: _handleGetStarted,
          ),
        ),

        if (_showForm) _buildFormOverlay(isTablet: false),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SplashHeroSectionWidget(
              showForm: _showForm,
              onGetStarted: _handleGetStarted,
            ),
          ),
        ),

        if (_showForm) _buildFormOverlay(isTablet: true),
      ],
    );
  }

  Widget _buildFormOverlay({required bool isTablet}) {
    final size = MediaQuery.of(context).size;

    final maxWidth = isTablet ? 430.0 : 420.0;
    final horizontalPadding = isTablet ? 32.0 : 18.0;
    final verticalPadding = isTablet ? 32.0 : 18.0;

    final maxHeight = isTablet
        ? size.height * 0.88
        : (_isLogin ? size.height * 0.78 : size.height * 0.92);

    return Positioned.fill(
      child: FadeTransition(
        opacity: _formFadeAnimation,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: isTablet ? _hideForm : null,
                child: Container(
                  color: AppTheme.backgroundLight.withAlpha(
                    isTablet ? 226 : 238,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: SlideTransition(
                    position: _formSlideAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                      ),
                      child: AuthFormWidget(
                        isLogin: _isLogin,
                        onToggleMode: _toggleMode,
                        onAuthSuccess: _handleAuthSuccess,
                      ),
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