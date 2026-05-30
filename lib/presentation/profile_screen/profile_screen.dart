import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _profilePhoto;
  final ImagePicker _picker = ImagePicker();

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Photo',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A foto será usada para reconhecimento facial',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 20),
              _buildPhotoOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tirar foto',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.photo_library_outlined,
                label: 'Escolher da Galeria',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profilePhoto != null) ...[
                const SizedBox(height: 12),
                _buildPhotoOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remover foto',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _profilePhoto = null);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppTheme.darkText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _profilePhoto = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível acessar a ${source == ImageSource.camera ? 'câmera' : 'galeria'}. Por favor verifique as permições.',
              style: GoogleFonts.outfit(fontSize: 13),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildMemberCard(context)),
            SliverToBoxAdapter(child: _buildStatsRow(context)),
            SliverToBoxAdapter(child: _buildMenuSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 18,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _profilePhoto == null
                          ? const LinearGradient(
                              colors: [Color(0xFF4CAF7D), Color(0xFF2E7D52)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _profilePhoto != null ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: _profilePhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: kIsWeb
                                ? Image.network(
                                    _profilePhoto!.path,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    semanticLabel: 'Profile photo of Maya Chen',
                                  )
                                : Image.file(
                                    File(_profilePhoto!.path),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    semanticLabel: 'Profile photo of Maya Chen',
                                  ),
                          )
                        : Center(
                            child: Text(
                              'MC',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maya Chen',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'maya.chen@borghetto.com',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFE8A020),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gold Member',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8A020),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '2,847',
              'Points',
              Icons.stars_rounded,
              AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '14',
              'Visits',
              Icons.storefront_outlined,
              AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '\$342',
              'Saved',
              Icons.savings_outlined,
              Color(0xFFE8A020),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.history_rounded,
        'label': 'Access Log History',
        'subtitle': 'View door access records',
        'onTap': () => context.push(AppRoutes.accessLogScreen),
        'accent': true,
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Membership Card',
        'subtitle': 'View your digital card',
        'onTap': () => context.go(AppRoutes.digitalMembershipCardScreen),
        'accent': false,
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'subtitle': 'Manage alert preferences',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'Privacy & Security',
        'subtitle': 'Password, biometrics',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Help & Support',
        'subtitle': 'FAQs and contact us',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.logout_rounded,
        'label': 'Sign Out',
        'subtitle': 'Log out of your account',
        'onTap': () => context.go(AppRoutes.signUpLoginScreen),
        'accent': false,
        'danger': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: List.generate(menuItems.length, (i) {
                final item = menuItems[i];
                final isDanger = item['danger'] == true;
                final isAccent = item['accent'] == true;
                final color = isDanger
                    ? AppTheme.error
                    : isAccent
                    ? AppTheme.accent
                    : AppTheme.darkText;

                return Column(
                  children: [
                    InkWell(
                      onTap: item['onTap'] as VoidCallback,
                      borderRadius: BorderRadius.circular(16.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDanger
                                    ? AppTheme.error.withAlpha(20)
                                    : isAccent
                                    ? AppTheme.accentLight
                                    : AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    item['subtitle'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isDanger)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppTheme.mutedText,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (i < menuItems.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.outlineLight,
                        indent: 66,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
