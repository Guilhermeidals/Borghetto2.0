import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../theme/app_theme.dart';
import '../models/admin_app_user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const List<_AdminUserFilter> _filters = [
    _AdminUserFilter(label: 'Pendentes', value: 'pending'),
    _AdminUserFilter(label: 'Aprovados', value: 'approved'),
    _AdminUserFilter(label: 'Bloqueados', value: 'blocked'),
    _AdminUserFilter(label: 'Negados', value: 'rejected'),
    _AdminUserFilter(label: 'Todos', value: 'all'),
  ];

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'pending';
  List<AdminAppUser> _users = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  int? _updatingUserId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final users = await ApiClient.instance.getAdminAppUsers(
        status: _selectedStatus,
        search: _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
      });
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      _showSnackBar('Erro inesperado ao buscar usuários.', isError: true);
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadUsers();
    });
  }

  void _changeFilter(String status) {
    if (_selectedStatus == status) {
      return;
    }

    setState(() {
      _selectedStatus = status;
    });

    _loadUsers();
  }

  Future<void> _toggleApproval(AdminAppUser user, bool approved) async {
    setState(() {
      _updatingUserId = user.id;
    });

    try {
      final updatedUser = await ApiClient.instance.updateAdminUserApproval(
        userId: user.id,
        approved: approved,
        reviewNote: approved ? null : 'Bloqueio manual pelo administrador',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final index = _users.indexWhere((item) => item.id == user.id);

        if (index >= 0) {
          _users[index] = updatedUser;
        }

        if (_selectedStatus != 'all' &&
            updatedUser.approvalStatus != _selectedStatus) {
          _users.removeWhere((item) => item.id == user.id);
        }
      });

      _showSnackBar(
        approved ? 'Usuário aprovado.' : 'Usuário bloqueado.',
      );
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      _showSnackBar(
        'Erro inesperado ao alterar aprovação.',
        isError: true,
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _updatingUserId = null;
      });
    }
  }

  Future<void> _logoutAllUserSessions(AdminAppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Derrubar sessões?'),
          content: Text(
            'Isso vai desconectar ${user.name} de todos os dispositivos. '
            'Ele precisará fazer login novamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Derrubar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiClient.instance.logoutAllUserSessions(user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sessões de ${user.name} derrubadas com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.primary,
      ),
    );
  }

  String _statusLabel(AdminAppUser user) {
    switch (user.approvalStatus) {
      case 'approved':
        return 'Aprovado';
      case 'blocked':
        return 'Bloqueado';
      case 'rejected':
        return 'Negado';
      case 'pending':
      default:
        return 'Pendente';
    }
  }

  String? _absolutePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return null;
    }

    final clean = photoUrl.trim();

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    return '${ApiClient.baseUrl}$clean';
  }

  Color _statusColor(AdminAppUser user) {
    switch (user.approvalStatus) {
      case 'approved':
        return AppTheme.success;
      case 'blocked':
        return AppTheme.error;
      case 'rejected':
        return AppTheme.coffee;
      case 'pending':
      default:
        return AppTheme.warning;
    }
  }

  String _formatCpf(String? value) {
    final cpf = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cpf.length != 11) {
      return value?.trim().isNotEmpty == true ? value!.trim() : 'CPF não informado';
    }

    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  String _formatPhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }

    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    return value?.trim().isNotEmpty == true ? value!.trim() : 'Telefone não informado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadUsers(refresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearch()),
              SliverToBoxAdapter(child: _buildFilters()),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_users.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildUserCard(_users[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoAvatar({
    required String name,
    required String? photoUrl,
    double radius = 23,
  }) {
    final absoluteUrl = _absolutePhotoUrl(photoUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.forestMist,
      backgroundImage: absoluteUrl == null ? null : NetworkImage(absoluteUrl),
      onBackgroundImageError: absoluteUrl == null ? null : (_, __) {},
      child: absoluteUrl != null
          ? null
          : Text(
              name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
    );
  }

  Widget _buildDependentsPreview(AdminAppUser user) {
    final dependents = user.dependents.take(4).toList();
    final remaining = user.dependents.length - dependents.length;

    return Row(
      children: [
        SizedBox(
          width: (dependents.length * 24) + (remaining > 0 ? 32 : 0),
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < dependents.length; i++)
                Positioned(
                  left: i * 22,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: _buildPhotoAvatar(
                      name: dependents[i].name,
                      photoUrl: dependents[i].photoUrl,
                      radius: 13,
                    ),
                  ),
                ),
              if (remaining > 0)
                Positioned(
                  left: dependents.length * 22,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppTheme.surfaceVariantLight,
                      child: Text(
                        '+$remaining',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            user.dependents.length == 1
                ? '1 dependente'
                : '${user.dependents.length} dependentes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Aprovação de usuários',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
          ),
          IconButton(
            onPressed: _isRefreshing ? null : () => _loadUsers(refresh: true),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por nome, e-mail, CPF ou telefone',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter.value == _selectedStatus;

          return ChoiceChip(
            selected: selected,
            label: Text(filter.label),
            onSelected: (_) => _changeFilter(filter.value),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(AdminAppUser user) {
    final isUpdating = _updatingUserId == user.id;
    final color = _statusColor(user);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context.push('/admin-users/${user.id}');

          if (!mounted) {
            return;
          }

          await _loadUsers(refresh: true);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outlineLight),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoAvatar(
                name: user.name,
                photoUrl: user.photoUrl,
                radius: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.trim().isEmpty ? 'Sem nome' : user.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email.trim().isEmpty
                          ? 'E-mail não informado'
                          : user.email,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusPill(
                          label: _statusLabel(user),
                          color: color,
                        ),
                        _buildInfoPill(
                          icon: Icons.badge_outlined,
                          label: _formatCpf(user.cpf),
                        ),
                        _buildInfoPill(
                          icon: Icons.phone_outlined,
                          label: _formatPhone(user.phone),
                        ),
                      ],
                    ),
                    if (user.dependents.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDependentsPreview(user),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isUpdating
                        ? const SizedBox(
                            width: 44,
                            height: 32,
                            child: Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          )
                        : Switch.adaptive(
                            value: user.approved,
                            activeColor: AppTheme.success,
                            onChanged: (value) => _toggleApproval(user, value),
                          ),
                    const SizedBox(height: 8),
                    Tooltip(
                      message: 'Derrubar sessões',
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 21,
                          color: AppTheme.danger,
                        ),
                        onPressed: isUpdating
                            ? null
                            : () => _logoutAllUserSessions(user),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: AppTheme.radiusPill,
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: AppTheme.radiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.mutedText),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 42,
              color: AppTheme.mutedText.withAlpha(150),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum usuário encontrado',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Altere o filtro ou a busca para consultar outros cadastros.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUserFilter {
  const _AdminUserFilter({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}