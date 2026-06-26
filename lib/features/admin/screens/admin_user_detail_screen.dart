import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../theme/app_theme.dart';
import '../models/admin_user_detail.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({
    required this.userId,
    super.key,
  });

  final int userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  AdminUserDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await ApiClient.instance.getAdminUserDetail(
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Erro ao carregar detalhes do usuário';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Detalhes do usuário',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: _buildBody(detail),
      ),
    );
  }

  Widget _buildBody(AdminUserDetail? detail) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildErrorCard(),
        ],
      );
    }

    if (detail == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildEmptyCard(),
        ],
      );
    }

    final user = detail.user;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildHeaderCard(detail),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Dados cadastrais',
          children: [
            _InfoRow(label: 'ID interno', value: user.id.toString()),
            _InfoRow(label: 'Nome', value: user.name),
            _InfoRow(label: 'E-mail', value: user.email),
            _InfoRow(label: 'CPF', value: _fallback(user.cpf)),
            _InfoRow(label: 'Telefone', value: _fallback(user.phone)),
            _InfoRow(
              label: 'Nascimento',
              value: _formatDate(user.birthDate),
            ),
            _InfoRow(label: 'Tipo', value: _fallback(user.role)),
          ],
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Endereço',
          children: [
            _InfoRow(label: 'CEP', value: _fallback(user.zipCode)),
            _InfoRow(label: 'Rua', value: _fallback(user.street)),
            _InfoRow(label: 'Número', value: _fallback(user.number)),
            _InfoRow(label: 'Complemento', value: _fallback(user.complement)),
            _InfoRow(label: 'Bairro', value: _fallback(user.neighborhood)),
            _InfoRow(label: 'Cidade', value: _fallback(user.city)),
            _InfoRow(label: 'UF', value: _fallback(user.state)),
          ],
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Status e aprovação',
          children: [
            _InfoRow(
              label: 'Ativo',
              value: user.active == true ? 'Sim' : 'Não',
            ),
            _InfoRow(
              label: 'Aprovado',
              value: user.approved ? 'Sim' : 'Não',
            ),
            _InfoRow(
              label: 'Status aprovação',
              value: _translateApprovalStatus(user.approvalStatus),
            ),
            _InfoRow(
              label: 'Nota revisão',
              value: _fallback(user.reviewNote),
            ),
            _InfoRow(
              label: 'Revisado em',
              value: _formatDateTime(user.reviewedAt),
            ),
            _InfoRow(
              label: 'Revisado por ID',
              value: user.reviewedBy?.toString() ?? '-',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Control iD',
          children: [
            _InfoRow(
              label: 'ID Control iD',
              value: user.controlIdUserId?.toString() ?? '-',
            ),
            _InfoRow(
              label: 'Vinculado',
              value: user.controlIdUserId != null && user.controlIdUserId! > 0
                  ? 'Sim'
                  : 'Não',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildDependentsCard(detail),
      ],
    );
  }

  Widget _buildHeaderCard(AdminUserDetail detail) {
    final user = detail.user;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withAlpha(40),
            child: Text(
              user.name.isNotEmpty ? user.name.characters.first.toUpperCase() : '?',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: _translateApprovalStatus(user.approvalStatus),
                      backgroundColor: Colors.white.withAlpha(32),
                      textColor: Colors.white,
                    ),
                    _StatusChip(
                      label: '${detail.dependents.length} dependente(s)',
                      backgroundColor: Colors.white.withAlpha(32),
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDependentsCard(AdminUserDetail detail) {
    final dependents = detail.dependents;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Dependentes',
            trailing: Text(
              dependents.length.toString(),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (dependents.isEmpty)
            Text(
              'Nenhum dependente cadastrado.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
              ),
            )
          else
            ...dependents.map(_buildDependentItem),
        ],
      ),
    );
  }

  Widget _buildDependentItem(AdminUserDependent dependent) {
    final active = dependent.active == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: active
                    ? AppTheme.success.withAlpha(25)
                    : AppTheme.error.withAlpha(25),
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 18,
                  color: active ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dependent.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              _StatusChip(
                label: active ? 'Ativo' : 'Inativo',
                backgroundColor: active
                    ? AppTheme.success.withAlpha(22)
                    : AppTheme.error.withAlpha(22),
                textColor: active ? AppTheme.success : AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'ID', value: dependent.id.toString()),
          _InfoRow(label: 'CPF', value: _fallback(dependent.cpf)),
          _InfoRow(
            label: 'Nascimento',
            value: _formatDate(dependent.birthDate),
          ),
          _InfoRow(
            label: 'Parentesco',
            value: _fallback(dependent.relationship),
          ),
          _InfoRow(
            label: 'ID Control iD',
            value: dependent.controlIdUserId?.toString() ?? '-',
          ),
          _InfoRow(
            label: 'Criado em',
            value: _formatDateTime(dependent.createdAt),
          ),
          _InfoRow(
            label: 'Atualizado em',
            value: _formatDateTime(dependent.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Erro ao carregar detalhes',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadDetail,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        'Nenhum detalhe encontrado.',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkText,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: AppTheme.outlineLight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  String _fallback(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) {
      return '-';
    }

    return clean;
  }

  String _translateApprovalStatus(String value) {
    switch (value.toLowerCase().trim()) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'blocked':
        return 'Bloqueado';
      case 'rejected':
        return 'Negado';
      default:
        return value;
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}