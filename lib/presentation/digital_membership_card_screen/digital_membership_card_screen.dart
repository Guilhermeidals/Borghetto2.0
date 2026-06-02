import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/door_access_widget.dart';
import './widgets/member_benefits_widget.dart';
import './widgets/membership_card_widget.dart';
import './widgets/points_summary_row_widget.dart';

class DigitalMembershipCardScreen extends StatefulWidget {
  const DigitalMembershipCardScreen({super.key});

  @override
  State<DigitalMembershipCardScreen> createState() =>
      _DigitalMembershipCardScreenState();
}

class _DigitalMembershipCardScreenState
    extends State<DigitalMembershipCardScreen> {
  AuthSession? _session;
  bool _isLoadingSession = true;

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
    }
  }

  String get _memberName {
    final name = _session?.name.trim();

    if (name == null || name.isEmpty) {
      return 'Cliente Borghetto';
    }

    return name;
  }

  String get _memberId {
    final facialUserId = _session?.controlIdUserId ?? 0;

    if (facialUserId <= 0) {
      return 'BG-000000';
    }

    return 'BG-${facialUserId.toString().padLeft(6, '0')}';
  }

  String get _memberCpf {
    final cpf = _session?.cpf?.trim();

    if (cpf == null || cpf.isEmpty) {
      return 'CPF não informado';
    }

    return _formatCpf(cpf);
  }

  String get _memberPhone {
    final phone = _session?.phone?.trim();

    if (phone == null || phone.isEmpty) {
      return 'Telefone não informado';
    }

    return _formatPhone(phone);
  }

  String _formatPhone(String value) {
    final digits = _onlyDigits(value);

    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
    }

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
    }

    return value;
  }
  
  String? get _photoUrl {
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

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatCpf(String value) {
    final digits = _onlyDigits(value);

    if (digits.length != 11) {
      return value;
    }

    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9, 11)}';
  }

  String get _tier {
    final accessStatus = _session?.accessStatus?.trim();

    if (accessStatus == null || accessStatus.isEmpty) {
      return 'Cliente';
    }

    if (accessStatus == 'active' || accessStatus == 'approved') {
      return 'Ativo';
    }

    if (accessStatus == 'pending') {
      return 'Pendente';
    }

    if (accessStatus == 'blocked') {
      return 'Bloqueado';
    }

    return 'Cliente';
  }

  int get _points {
    return 0;
  }

  int get _redeemable {
    return 0;
  }

  int get _thisMonth {
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout(context) : _buildPhoneLayout(context),
      ),
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: MembershipCardWidget(
              memberName: _memberName,
              memberCpf: _memberCpf,
              memberPhone: _memberPhone,
              memberId: _memberId,
              tier: _tier,
              points: _points,
              photoUrl: _photoUrl,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: PointsSummaryRowWidget(
              points: _points,
              redeemable: _redeemable,
              thisMonth: _thisMonth,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: DoorAccessWidget(),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: MemberBenefitsWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: MembershipCardWidget(
                memberName: _memberName,
                memberCpf: _memberCpf,
                memberPhone: _memberPhone,
                memberId: _memberId,
                tier: _tier,
                points: _points,
                photoUrl: _photoUrl,
              ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: PointsSummaryRowWidget(
                  points: _points,
                  redeemable: _redeemable,
                  thisMonth: _thisMonth,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: DoorAccessWidget(),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: MemberBenefitsWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.homeScreen),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outlineLight, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppTheme.darkText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Meu Clube',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outlineLight, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppTheme.darkText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}