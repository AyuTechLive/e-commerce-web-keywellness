// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/website_content_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/product_card.dart';
import '../widgets/category_product_card.dart';
import '../models/website_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Load website content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebsiteContentProvider>(context, listen: false)
          .loadWebsiteConfig();
    });

    _startBannerAutoSlide();
  }

  void _startBannerAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        final provider =
            Provider.of<WebsiteContentProvider>(context, listen: false);
        final bannerCount = provider.activeBanners.length;
        if (bannerCount > 0) {
          _nextBanner(bannerCount);
          _startBannerAutoSlide();
        }
      }
    });
  }

  void _nextBanner(int bannerCount) {
    if (_currentBannerIndex < bannerCount - 1) {
      _currentBannerIndex++;
    } else {
      _currentBannerIndex = 0;
    }
    if (_bannerController.hasClients) {
      _bannerController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebsiteContentProvider>(
      builder: (context, websiteProvider, child) {
        final websiteConfig = websiteProvider.websiteConfig;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFBFC),
          appBar: CustomAppBar(
            currentRoute: '/',
            siteName: websiteConfig?.siteName,
            logoUrl: websiteConfig?.logoUrl,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroBannerSection(websiteProvider),
                  _buildQuickStatsSection(websiteProvider),
                  _buildCategoriesSection(),
                  _buildFeaturedProductsSection(),
                  _buildDealsSection(),
                  _buildSaleProductsSection(),
                  _buildNewsletterSection(websiteConfig),
                  _buildFooterSection(websiteConfig),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaleProductsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final bool isDesktop = constraints.maxWidth >= 1024;

        return Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return const SizedBox.shrink();
            }

            final saleProducts = productProvider.products
                .where((product) => product.isOnSale)
                .take(15)
                .toList();

            if (saleProducts.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              color: const Color(0xFFFAFBFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B6B),
                                        Color(0xFFFFE66D)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_offer,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sale Products',
                                  style: TextStyle(
                                    fontSize: isMobile ? 24 : 32,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1A365D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Limited time offers • Up to ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Consumer<ProductProvider>(
                                  builder: (context, provider, child) {
                                    final maxDiscount = provider.products
                                        .where((p) => p.isOnSale)
                                        .fold<double>(0, (max, product) {
                                      final discount =
                                          product.calculatedDiscountPercentage;
                                      return discount > max ? discount : max;
                                    });

                                    return Text(
                                      '${maxDiscount.toStringAsFixed(0)}% OFF',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${saleProducts.length} ITEMS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFFE66D)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B6B)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    context.go('/products?filter=sale'),
                                icon: const Icon(Icons.local_offer),
                                label: const Text('View All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isMobile) ...[
                    // Mobile: Horizontal scroll
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 20),
                        itemCount: saleProducts.length,
                        itemBuilder: (context, index) {
                          final product = saleProducts[index];
                          return Container(
                            width: 200,
                            margin: EdgeInsets.only(
                              right: index < saleProducts.length - 1 ? 16 : 0,
                            ),
                            child: ProductCard(product: product),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Desktop/Tablet: Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 5 : 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: saleProducts.take(isDesktop ? 5 : 3).length,
                      itemBuilder: (context, index) {
                        final product = saleProducts[index];
                        return ProductCard(product: product);
                      },
                    ),
                  ],
                  if (isMobile) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/products?filter=sale'),
                          icon: const Icon(Icons.local_offer),
                          label: const Text('View All Sale Products'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroBannerSection(WebsiteContentProvider websiteProvider) {
    final banners = websiteProvider.activeBanners;

    if (banners.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9, // 16:9 ratio
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return AspectRatio(
          aspectRatio: 16 / 9, // Fixed 16:9 ratio for all banners
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerSlide(
                banner: banner,
                isMobile: isMobile,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBannerSlide({
    required BannerItem banner,
    required bool isMobile,
  }) {
    // Convert hex colors to Color objects
    final colors = banner.gradientColors.map((hex) {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    }).toList();

    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        image: banner.backgroundImageUrl?.isNotEmpty == true
            ? DecorationImage(
                image: NetworkImage(banner.backgroundImageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (!isMobile) const Spacer(),
                if (banner.badgeText.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${banner.badgeIcon} ${banner.badgeText}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (banner.badgeText.isNotEmpty) const SizedBox(height: 24),
                Text(
                  banner.title,
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: 16),
                Text(
                  banner.subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: isMobile
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (banner.buttonAction?.isNotEmpty == true) {
                          if (banner.buttonAction!.startsWith('http')) {
                            _launchUrl(banner.buttonAction!);
                          } else {
                            context.go(banner.buttonAction!);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 32,
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner.buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => context.go('/about'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Learn More',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isMobile) const Spacer(),
              ],
            ),
          ),

          // Page Indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildPageIndicators(
                Provider.of<WebsiteContentProvider>(context)
                    .activeBanners
                    .length),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentBannerIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentBannerIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildQuickStatsSection(WebsiteContentProvider websiteProvider) {
    final stats = websiteProvider.activeStats;

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final websiteConfig = websiteProvider.websiteConfig;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: Colors.white,
          child: Column(
            children: [
              Text(
                'Why Choose ${websiteConfig?.siteName ?? 'Us'}',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 32),
              isMobile
                  ? _buildMobileStatsLayout(stats)
                  : _buildDesktopStatsLayout(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileStatsLayout(List<StatItem> stats) {
    return Column(
      children: List.generate((stats.length / 2).ceil(), (rowIndex) {
        final int startIndex = rowIndex * 2;
        final int endIndex = (startIndex + 2).clamp(0, stats.length);
        final List<StatItem> rowStats = stats.sublist(startIndex, endIndex);

        return Padding(
          padding: EdgeInsets.only(
              bottom: rowIndex < (stats.length / 2).ceil() - 1 ? 16 : 0),
          child: Row(
            children: [
              for (int i = 0; i < rowStats.length; i++) ...[
                Expanded(flex: 1, child: _buildStatCard(rowStats[i])),
                if (i < rowStats.length - 1) const SizedBox(width: 16),
              ],
              // Add spacer if odd number of items in last row
              if (rowStats.length == 1)
                const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopStatsLayout(List<StatItem> stats) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;

        return Expanded(
          flex: 1, // Equal width for all columns
          child: Padding(
            padding: EdgeInsets.only(
              left: index > 0 ? 12 : 0,
              right: index < stats.length - 1 ? 12 : 0,
            ),
            child: _buildStatCard(stat),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(StatItem stat) {
    // Convert hex colors to Color objects
    final colors = stat.gradientColors.map((hex) {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    }).toList();

    // Get icon data from icon name
    IconData iconData = _getIconFromName(stat.iconName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          height: isMobile ? 160 : 180, // Fixed height for consistency
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(iconData,
                    color: Colors.white, size: isMobile ? 24 : 32),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Number
              Text(
                stat.number,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A365D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Label
              Text(
                stat.label,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to convert icon name to IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'people_outline':
        return Icons.people_outline;
      case 'inventory_2_outlined':
        return Icons.inventory_2_outlined;
      case 'star_outline':
        return Icons.star_outline;
      case 'support_agent_outlined':
        return Icons.support_agent_outlined;
      case 'verified_outlined':
        return Icons.verified_outlined;
      case 'local_shipping_outlined':
        return Icons.local_shipping_outlined;
      default:
        return Icons.star_outline;
    }
  }

  // Helper method to launch URLs
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildCategoriesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final bool isDesktop = constraints.maxWidth >= 1024;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: const Color(0xFFFAFBFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop by Category',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A365D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explore our wide range of categories',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (!isMobile)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/categories'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('View All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                      ),
                    );
                  }

                  final categories =
                      categoryProvider.categories.take(15).toList();

                  // Use GridView for all screen sizes
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (isDesktop ? 5 : 4),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 1.0 : 1.1,
                    ),
                    itemCount: isMobile
                        ? categories.take(6).length
                        : categories.take(isDesktop ? 5 : 4).length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return CategoryCard(category: category);
                    },
                  );
                },
              ),
              if (isMobile) ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/categories'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View All Categories'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProductsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final bool isDesktop = constraints.maxWidth >= 1024;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Featured Products',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A365D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hand-picked products for you',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🔥 HOT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4AA).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/products'),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('View All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                      ),
                    );
                  }

                  final products =
                      productProvider.featuredProducts.take(15).toList();

                  if (isMobile) {
                    // Mobile: Horizontal scroll
                    return SizedBox(
                      height: 400,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 20),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            width: 200,
                            margin: EdgeInsets.only(
                              right: index < products.length - 1 ? 16 : 0,
                            ),
                            child: ProductCard(product: product),
                          );
                        },
                      ),
                    );
                  } else {
                    // Desktop/Tablet: Grid
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 5 : 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.55,
                      ),
                      itemCount: products.take(isDesktop ? 5 : 3).length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(product: product);
                      },
                    );
                  }
                },
              ),
              if (isMobile) ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/products'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View All Products'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDealsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final saleProducts = productProvider.products
                .where((product) => product.isOnSale)
                .toList();

            final totalSavings = saleProducts.fold<double>(0, (sum, product) {
              return sum + product.savingsAmount;
            });

            final averageDiscount = saleProducts.isNotEmpty
                ? saleProducts.fold<double>(0, (sum, product) {
                      return sum + product.calculatedDiscountPercentage;
                    }) /
                    saleProducts.length
                : 0;

            return Container(
              margin: EdgeInsets.all(isMobile ? 20 : 40),
              padding: EdgeInsets.all(isMobile ? 24 : 40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            saleProducts.isNotEmpty
                                ? '⚡ ${saleProducts.length} ITEMS ON SALE'
                                : '⚡ LIMITED TIME',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isMobile ? 'Special Deals' : 'Special Deals & Offers',
                          style: TextStyle(
                            fontSize: isMobile ? 28 : 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          saleProducts.isNotEmpty
                              ? 'Up to ${averageDiscount.toStringAsFixed(0)}% off • Save up to ₹${totalSavings.toStringAsFixed(0)}!'
                              : 'Up to 70% off on selected items. Limited time only!',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/products?filter=sale'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667EEA),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 32,
                              vertical: isMobile ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                saleProducts.isNotEmpty
                                    ? 'Shop Deals'
                                    : 'Shop Now',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.local_offer),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 40),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          if (saleProducts.isNotEmpty) ...[
                            Text(
                              '${saleProducts.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'ITEMS ON SALE',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewsletterSection(WebsiteConfig? websiteConfig) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final siteName = websiteConfig?.siteName ?? 'WellnessHub';

        return Container(
          margin: EdgeInsets.all(isMobile ? 20 : 40),
          padding: EdgeInsets.all(isMobile ? 24 : 40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A365D), Color(0xFF2D3748)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                'Stay Updated with $siteName',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Get the latest updates on new products, exclusive offers, and flash sales',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                constraints:
                    BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
                child: isMobile
                    ? Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter your email for deals',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Subscribe for Deals',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Enter your email for exclusive deals',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Subscribe',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterSection(WebsiteConfig? websiteConfig) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final siteName = websiteConfig?.siteName ?? 'WellnessHub';
        final logoUrl = websiteConfig?.logoUrl;
        final description = websiteConfig?.description ??
            'Your trusted partner for premium quality products. We deliver excellence with every purchase and amazing deals.';
        final footerText = websiteConfig?.footerText ??
            '© 2024 WellnessHub. All rights reserved.';
        final socialMedia = websiteConfig?.socialMedia;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: const Color(0xFF1A365D),
          child: Column(
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterBrand(siteName, logoUrl, description),
                    const SizedBox(height: 32),
                    _buildFooterLinks(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2,
                        child:
                            _buildFooterBrand(siteName, logoUrl, description)),
                    Expanded(flex: 3, child: _buildFooterLinks()),
                  ],
                ),
              const SizedBox(height: 32),
              Divider(color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      footerText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (!isMobile && socialMedia != null)
                    Row(
                      children: [
                        if (socialMedia.facebook.isNotEmpty)
                          _buildSocialButton(
                              Icons.facebook, socialMedia.facebook),
                        if (socialMedia.instagram.isNotEmpty)
                          _buildSocialButton(
                              Icons.camera_alt, socialMedia.instagram),
                        if (socialMedia.twitter.isNotEmpty)
                          _buildSocialButton(
                              Icons.alternate_email, socialMedia.twitter),
                        if (socialMedia.whatsapp.isNotEmpty)
                          _buildSocialButton(Icons.message,
                              'https://wa.me/${socialMedia.whatsapp}'),
                        if (socialMedia.email.isNotEmpty)
                          _buildSocialButton(
                              Icons.email, 'mailto:${socialMedia.email}'),
                      ]
                          .where((widget) => widget != null)
                          .map((widget) => Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: widget!,
                              ))
                          .toList(),
                    ),
                ],
              ),
              if (isMobile && socialMedia != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    if (socialMedia.facebook.isNotEmpty)
                      _buildSocialButton(Icons.facebook, socialMedia.facebook),
                    if (socialMedia.instagram.isNotEmpty)
                      _buildSocialButton(
                          Icons.camera_alt, socialMedia.instagram),
                    if (socialMedia.twitter.isNotEmpty)
                      _buildSocialButton(
                          Icons.alternate_email, socialMedia.twitter),
                    if (socialMedia.whatsapp.isNotEmpty)
                      _buildSocialButton(Icons.message,
                          'https://wa.me/${socialMedia.whatsapp}'),
                    if (socialMedia.email.isNotEmpty)
                      _buildSocialButton(
                          Icons.email, 'mailto:${socialMedia.email}'),
                  ].where((widget) => widget != null).cast<Widget>().toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterBrand(
      String siteName, String? logoUrl, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (logoUrl?.isNotEmpty == true)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            Text(
              siteName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 400;

        if (isMobile) {
          return Column(
            children: [
              _buildFooterColumn('Quick Links', [
                'About Us',
                // 'Our Story',
                'Sale Products',
                // 'Careers',
              ]),
              const SizedBox(height: 24),
              _buildFooterColumn('Customer Care', [
                'Help Center',
                'Shipping Info',
                'Returns',
                'Track Order',
              ]),
              const SizedBox(height: 24),
              _buildFooterColumn('Legal', [
                'Privacy Policy',
                'Terms of Service',
                'Refund Policy',
                //   'Accessibility',
              ]),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFooterColumn('Quick Links', [
              'About Us',
              // 'Our Story',
              'Sale Products',
              //'Careers',
            ]),
            _buildFooterColumn('Customer Care', [
              'Help Center',
              'Shipping Info',
              //'Returns',
              'Track Order',
            ]),
            _buildFooterColumn('Legal', [
              'Privacy Policy',
              'Terms of Service',
              'Refund Policy',
              //  'Accessibility',
            ]),
          ],
        );
      },
    );
  }

  Widget _buildFooterColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  switch (link.toLowerCase()) {
                    case 'about us':
                      context.go('/about');
                      break;
                    case 'sale products':
                      context.go('/products?filter=sale');
                      break;

                    case 'refund policy':
                      context.go('/refund');
                      break;

                    case 'help center':
                      context.go('/contact-us');
                      break;
                    case 'shipping info':
                      context.go('/profile');
                      break;
                    case 'track order':
                      context.go('/profile');
                      break;

                    case 'privacy policy':
                      context.go('/privacy');
                      break;
                    case 'terms of service':
                      context.go('/terms');
                      break;
                    default:
                      break;
                  }
                },
                child: Text(
                  link,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget? _buildSocialButton(IconData icon, String url) {
    if (url.isEmpty) return null;

    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// Custom Painter for Background Pattern (unchanged)
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw circles
    for (int i = 0; i < 15; i++) {
      final x = (i * size.width / 8) % size.width;
      final y = (i * size.height / 10) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        15 + (i % 3) * 10,
        paint,
      );
    }

    // Draw triangles
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final x = (i * size.width / 5) % size.width;
      final y = (i * size.height / 7) % size.height;

      path.reset();
      path.moveTo(x, y);
      path.lineTo(x + 20, y + 30);
      path.lineTo(x - 20, y + 30);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
