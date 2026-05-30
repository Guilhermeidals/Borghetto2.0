import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import './widgets/door_access_widget.dart';
import './widgets/member_benefits_widget.dart';
import './widgets/membership_card_widget.dart';
import './widgets/points_summary_row_widget.dart';

class DigitalMembershipCardScreen extends StatelessWidget {
  const DigitalMembershipCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet
            ? _buildTabletLayout(context)
            : _buildPhoneLayout(context),
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
            child: const MembershipCardWidget(
              memberName: 'Maya Chen',
              memberId: 'SC-2024-00847',
              tier: 'Gold',
              expiryDate: '12/2027',
              points: 2847,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: const PointsSummaryRowWidget(
              points: 2847,
              redeemable: 284,
              thisMonth: 312,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: const DoorAccessWidget(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: const MemberBenefitsWidget(),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: MembershipCardWidget(
                  memberName: 'Maya Chen',
                  memberId: 'SC-2024-00847',
                  tier: 'Gold',
                  expiryDate: '12/2027',
                  points: 2847,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: PointsSummaryRowWidget(
                  points: 2847,
                  redeemable: 284,
                  thisMonth: 312,
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
            onTap: () => context.go('/home-screen'),
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
          Text(
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
