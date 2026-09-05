import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../theme/app_theme.dart';
import '../models/marketing_banner.dart';

class MarketingCarousel extends StatefulWidget {
  const MarketingCarousel({super.key});

  @override
  State<MarketingCarousel> createState() => _MarketingCarouselState();
}

class _MarketingCarouselState extends State<MarketingCarousel> {
  final PageController _pageController = PageController();
  List<MarketingBanner> _banners = [];
  Timer? _timer;
  Timer? _scheduleRefreshTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _scheduleRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadBanners(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scheduleRefreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await ApiClient.instance.getMarketingBanners();
      if (!mounted) return;

      final activeBanners = banners.where((banner) => banner.active).toList();
      final hasChanged = activeBanners.length != _banners.length ||
          List.generate(activeBanners.length, (index) {
            if (index >= _banners.length) return true;
            final current = _banners[index];
            final next = activeBanners[index];
            return current.id != next.id ||
                current.title != next.title ||
                current.imageUrl != next.imageUrl ||
                current.sortOrder != next.sortOrder;
          }).any((changed) => changed);

      if (!hasChanged) return;

      setState(() {
        _banners = activeBanners;
        _currentPage = 0;
      });
      _startAutoPlay();
    } catch (_) {
      // Campanhas são conteúdo opcional e não bloqueiam a tela inicial.
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (_banners.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _openBannerPreview(MarketingBanner banner) async {
    _timer?.cancel();

    final imageUrl = ApiClient.instance.resolveFileUrl(banner.imageUrl);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(190),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(
                width: 72,
                height: 72,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => const SizedBox(
                width: 240,
                height: 160,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Novidades',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AspectRatio(
            aspectRatio: 2 / 1,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final banner = _banners[index];
                final imageUrl = ApiClient.instance.resolveFileUrl(
                  banner.imageUrl,
                );

                return GestureDetector(
                  onTap: () => _openBannerPreview(banner),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceVariantLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceVariantLight,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ),
                        if (banner.title?.trim().isNotEmpty == true)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(18, 32, 18, 14),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black54],
                                ),
                              ),
                              child: Text(
                                banner.title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              final selected = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.outlineLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
