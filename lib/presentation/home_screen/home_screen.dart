import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/brand_section_header_widget.dart';
import './widgets/category_chips_widget.dart';
import './widgets/door_unlock_fab_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/offer_card_widget.dart';
import './widgets/points_hero_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedCategory = 0;

  final List<String> _categories = ['All', 'Fresh', 'Deals', 'Members'];

  // Mock data — Map-first pattern
  final List<Map<String, dynamic>> _offerMaps = [
    {
      'id': 'o1',
      'brand': 'Farm Fresh',
      'name': 'Organic Avocados',
      'price': 3.49,
      'originalPrice': 5.99,
      'discount': '42% OFF',
      'description': 'Hand-picked Hass avocados, perfectly ripe.',
      'imageUrl':
          'https://images.unsplash.com/photo-1609860798796-5e225e44cc04',
      'semanticLabel': 'Three ripe green avocados on a white surface',
      'category': 'Fresh',
      'membersOnly': true,
      'status': 'active',
    },
    {
      'id': 'o2',
      'brand': 'Farm Fresh',
      'name': 'Mixed Berry Punnet',
      'price': 4.99,
      'originalPrice': 7.50,
      'discount': '33% OFF',
      'description': 'Blueberries, raspberries & strawberries.',
      'imageUrl':
          'https://images.unsplash.com/photo-1664270377106-eec9af05c83a',
      'semanticLabel':
          'Mixed fresh berries including strawberries and blueberries in a punnet',
      'category': 'Fresh',
      'membersOnly': false,
      'status': 'active',
    },
    {
      'id': 'o3',
      'brand': 'Daily Bakery',
      'name': 'Sourdough Loaf',
      'price': 5.29,
      'originalPrice': 6.99,
      'discount': '24% OFF',
      'description': 'Slow-fermented, stone-baked sourdough.',
      'imageUrl':
          'https://images.unsplash.com/photo-1710949012959-11a6d60ea10f',
      'semanticLabel':
          'Freshly baked sourdough bread loaf with a golden crust on a wooden board',
      'category': 'Deals',
      'membersOnly': false,
      'status': 'active',
    },
    {
      'id': 'o4',
      'brand': 'Daily Bakery',
      'name': 'Almond Croissants',
      'price': 2.79,
      'originalPrice': 3.99,
      'discount': '30% OFF',
      'description': 'Flaky, buttery croissants with almond cream.',
      'imageUrl':
          'https://images.unsplash.com/photo-1629184337026-9a03097a745c',
      'semanticLabel':
          'Golden buttery croissants on a white plate with almond topping',
      'category': 'Deals',
      'membersOnly': true,
      'status': 'expiring',
    },
    {
      'id': 'o5',
      'brand': 'Members Select',
      'name': 'Premium Olive Oil',
      'price': 9.99,
      'originalPrice': 16.00,
      'discount': '38% OFF',
      'description': 'Extra virgin, cold-pressed, single estate.',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_196b445bb-1764778043502.png',
      'semanticLabel':
          'Bottle of premium golden olive oil with olives on a marble surface',
      'category': 'Members',
      'membersOnly': true,
      'status': 'active',
    },
    {
      'id': 'o6',
      'brand': 'Members Select',
      'name': 'Aged Cheddar Block',
      'price': 6.49,
      'originalPrice': 9.99,
      'discount': '35% OFF',
      'description': '18-month matured cheddar, sharp & creamy.',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18f631dc4-1772291948987.png',
      'semanticLabel':
          'Block of aged yellow cheddar cheese on a wooden cutting board',
      'category': 'Members',
      'membersOnly': true,
      'status': 'active',
    },
  ];

  late List<Map<String, dynamic>> _allOffers;
  late Map<String, List<Map<String, dynamic>>> _groupedOffers;

  @override
  void initState() {
    super.initState();
    _allOffers = _offerMaps;
    _buildGroupedOffers();
  }

  void _buildGroupedOffers() {
    final filtered = _selectedCategory == 0
        ? _allOffers
        : _allOffers
              .where((o) => o['category'] == _categories[_selectedCategory])
              .toList();

    _groupedOffers = {};
    for (final offer in filtered) {
      final brand = offer['brand'] as String;
      _groupedOffers.putIfAbsent(brand, () => []).add(offer);
    }
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategory = index;
      _buildGroupedOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeAppBarWidget(
                    onSearchTap: () {},
                    onCartTap: () {},
                    onAvatarTap: () {},
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: PointsHeroWidget(
                      memberName: 'Maya Chen',
                      points: 2847,
                      nextRewardPoints: 3000,
                      tier: 'Gold',
                      onCardTap: () =>
                          context.go(AppRoutes.digitalMembershipCardScreen),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: CategoryChipsWidget(
                      categories: _categories,
                      selectedIndex: _selectedCategory,
                      onSelected: _onCategorySelected,
                    ),
                  ),
                ),
                ..._buildOfferSections(isTablet),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            // Floating door unlock FAB
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              right: 24,
              child: DoorUnlockFabWidget(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOfferSections(bool isTablet) {
    final sections = <Widget>[];
    _groupedOffers.forEach((brand, offers) {
      sections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: BrandSectionHeaderWidget(brandName: brand, onViewAll: () {}),
          ),
        ),
      );
      sections.add(
        SliverToBoxAdapter(
          child: isTablet
              ? _buildTabletOfferGrid(offers)
              : _buildPhoneOfferRow(offers),
        ),
      );
    });
    if (_groupedOffers.isEmpty) {
      sections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Center(
              child: Text(
                'No offers in this category',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
        ),
      );
    }
    return sections;
  }

  Widget _buildPhoneOfferRow(List<Map<String, dynamic>> offers) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: offers.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: EdgeInsets.only(right: i < offers.length - 1 ? 12 : 0),
            child: OfferCardWidget(offer: offers[i]),
          );
        },
      ),
    );
  }

  Widget _buildTabletOfferGrid(List<Map<String, dynamic>> offers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: offers.length,
        itemBuilder: (context, i) => OfferCardWidget(offer: offers[i]),
      ),
    );
  }
}
