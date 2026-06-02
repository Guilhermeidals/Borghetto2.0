import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_session.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _profilePhoto;
  final ImagePicker _picker = ImagePicker();

  AuthSession? _session;

  bool _isLoadingSession = true;
  bool _isUploadingPhoto = false;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final session = await ApiClient.instance.getSavedSession();

      if (!mounted) return;

      setState(() {
        _session = session;
        _isLoadingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingSession = false;
      });

      _showSnackBar(
        'Não foi possível carregar os dados do perfil.',
        isError: true,
      );
    }
  }

  String get _displayName {
    final name = _session?.name.trim();

    if (name == null || name.isEmpty) {
      return 'Cliente Borghetto';
    }

    return name;
  }

  String get _displayEmail {
    final email = _session?.email?.trim();

    if (email == null || email.isEmpty) {
      return 'E-mail não informado';
    }

    return email;
  }

  String get _displayCpf {
    final cpf = _session?.cpf?.trim();

    if (cpf == null || cpf.isEmpty) {
      return 'CPF não informado';
    }

    return cpf;
  }

  String get _displayPhone {
    final phone = _session?.phone?.trim();

    if (phone == null || phone.isEmpty) {
      return 'Telefone não informado';
    }

    return phone;
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

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatPhone(String value) {
    final digits = _onlyDigits(value);

    if (digits.isEmpty) {
      return '';
    }

    if (digits.length <= 2) {
      return '(${digits}';
    }

    final ddd = digits.substring(0, 2);
    final number = digits.substring(2);

    if (number.length <= 4) {
      return '($ddd) $number';
    }

    if (digits.length <= 10) {
      final firstPart = number.substring(0, number.length - 4);
      final lastPart = number.substring(number.length - 4);
      return '($ddd) $firstPart-$lastPart';
    }

    final firstPart = number.substring(0, 5);
    final lastPart = number.substring(5, 9);
    return '($ddd) $firstPart-$lastPart';
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

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
                'Foto do perfil',
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
                label: 'Escolher da galeria',
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
                    setState(() {
                      _profilePhoto = null;
                    });
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
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 92,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _profilePhoto = image;
      });

      await _uploadProfilePhoto(image);
    } catch (_) {
      _showSnackBar(
        'Não foi possível acessar a ${source == ImageSource.camera ? 'câmera' : 'galeria'}. Verifique as permissões.',
        isError: true,
      );
    }
  }

  Future<void> _uploadProfilePhoto(XFile image) async {
  final session = _session;

  if (session == null || session.userId <= 0) {
    _showSnackBar(
      'Sessão não encontrada. Faça login novamente.',
      isError: true,
    );
    return;
  }

  final facialUserId = session.controlIdUserId;

  if (facialUserId == null || facialUserId <= 0) {
    _showSnackBar(
      'Usuário ainda não possui ID facial vinculado.',
      isError: true,
    );
    return;
  }

  if (kIsWeb) {
    _showSnackBar(
      'Envio de foto pela Web ainda não está habilitado.',
      isError: true,
    );
    return;
  }

  setState(() {
    _isUploadingPhoto = true;
  });

  try {
    final updatedSession = await ApiClient.instance.uploadSelfie(
      facialUserId: facialUserId,
      imageFile: File(image.path),
    );

    if (!mounted) return;

    setState(() {
      _session = updatedSession;
      _profilePhoto = null;
    });

    _showSnackBar('Foto enviada com sucesso.');
  } on ApiException catch (e) {
    _showSnackBar(e.message, isError: true);
  } catch (_) {
    _showSnackBar(
      'Erro inesperado ao enviar a foto.',
      isError: true,
    );
  } finally {
    if (mounted) {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }
}

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ApiClient.instance.logout();

    if (!mounted) return;

    context.go(AppRoutes.signUpLoginScreen);
  }

  Future<void> _showEditProfileDialog() async {
    final session = _session;

    if (session == null) {
      _showSnackBar(
        'Sessão não encontrada. Faça login novamente.',
        isError: true,
      );
      return;
    }

    final nameController = TextEditingController(text: session.name);
    final cpfController = TextEditingController(text: session.cpf ?? '');
    final phoneController = TextEditingController(text: _formatPhone(session.phone ?? ''),);
    final emailController = TextEditingController(text: session.email ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu nome';
                          }

                          if (value.trim().length < 3) {
                            return 'Informe um nome válido';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cpfController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                        ),
                        validator: (value) {
                          final cpf = _onlyDigits(value ?? '');

                          if (cpf.isEmpty) {
                            return 'Informe seu CPF';
                          }

                          if (cpf.length != 11) {
                            return 'O CPF precisa ter 11 números';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                          _PhoneInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                        ),
                        validator: (value) {
                          final phone = _onlyDigits(value ?? '');

                          if (phone.isEmpty) {
                            return 'Informe seu telefone';
                          }

                          if (phone.length < 10 || phone.length > 11) {
                            return 'Informe um telefone válido';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }

                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Informe um e-mail válido';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingProfile
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            _isSavingProfile = true;
                          });

                          await _saveProfile(
                            userId: session.userId,
                            name: nameController.text.trim(),
                            cpf: _onlyDigits(cpfController.text.trim()),
                            phone: _onlyDigits(phoneController.text.trim()),
                            email: emailController.text.trim(),
                          );

                          if (!mounted) return;

                          setDialogState(() {
                            _isSavingProfile = false;
                          });

                          if (Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: _isSavingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    cpfController.dispose();
    phoneController.dispose();
    emailController.dispose();

    if (mounted) {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Future<void> _saveProfile({
    required int userId,
    required String name,
    required String cpf,
    required String phone,
    required String email,
  }) async {
    try {
      final updatedSession = await ApiClient.instance.updateUser(
        userId: userId,
        name: name,
        cpf: cpf,
        phone: phone,
        email: email,
      );

      if (!mounted) return;

      setState(() {
        _session = updatedSession;
      });

      _showSnackBar('Perfil atualizado com sucesso.');
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      _showSnackBar(
        'Erro inesperado ao atualizar o perfil.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            'Perfil',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          GestureDetector(
            onTap: _showEditProfileDialog,
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
              onTap: _isUploadingPhoto ? null : _showPhotoOptions,
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
                    child: _buildAvatarContent(),
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
                      child: _isUploadingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(4),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
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
                    _displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayEmail,
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
                          'Cliente Borghetto',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE8A020),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showEditProfileDialog,
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

  Widget _buildAvatarContent() {
    if (_profilePhoto != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: kIsWeb
            ? Image.network(
                _profilePhoto!.path,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                semanticLabel: 'Foto de perfil de $_displayName',
              )
            : Image.file(
                File(_profilePhoto!.path),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                semanticLabel: 'Foto de perfil de $_displayName',
              ),
      );
    }

    if (_serverPhotoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Image.network(
          _serverPhotoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          semanticLabel: 'Foto de perfil de $_displayName',
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _initials,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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
              '0',
              'Pontos',
              Icons.stars_rounded,
              AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '0',
              'Visitas',
              Icons.storefront_outlined,
              AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'R\$ 0',
              'Economia',
              Icons.savings_outlined,
              const Color(0xFFE8A020),
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
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.history_rounded,
        'label': 'Histórico de acesso',
        'subtitle': 'Veja os registros de acesso',
        'onTap': () => context.push(AppRoutes.accessLogScreen),
        'accent': true,
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Carteirinha digital',
        'subtitle': 'Veja seu cartão de membro',
        'onTap': () => context.go(AppRoutes.digitalMembershipCardScreen),
        'accent': false,
      },
      {
        'icon': Icons.person_outline_rounded,
        'label': 'Dados do perfil',
        'subtitle': 'Nome, CPF, telefone e e-mail',
        'onTap': _showEditProfileDialog,
        'accent': false,
      },
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'Privacidade e segurança',
        'subtitle': 'Senha e biometria',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Ajuda e suporte',
        'subtitle': 'Dúvidas e contato',
        'onTap': () {},
        'accent': false,
      },
      {
        'icon': Icons.logout_rounded,
        'label': 'Sair',
        'subtitle': 'Encerrar sessão da conta',
        'onTap': _confirmLogout,
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
            'Conta',
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
class _PhoneInputFormatter extends TextInputFormatter {
  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatPhone(String value) {
    final digits = _onlyDigits(value);

    if (digits.isEmpty) {
      return '';
    }

    if (digits.length <= 2) {
      return '(${digits}';
    }

    final ddd = digits.substring(0, 2);
    final number = digits.substring(2);

    if (number.length <= 4) {
      return '($ddd) $number';
    }

    if (digits.length <= 10) {
      final firstPart = number.substring(0, number.length - 4);
      final lastPart = number.substring(number.length - 4);
      return '($ddd) $firstPart-$lastPart';
    }

    final firstPart = number.substring(0, 5);
    final lastPart = number.substring(5, 9);
    return '($ddd) $firstPart-$lastPart';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _onlyDigits(newValue.text);
    final limitedDigits =
        digits.length > 11 ? digits.substring(0, 11) : digits;

    final formatted = _formatPhone(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
