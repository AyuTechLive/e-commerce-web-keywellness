import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/product_card.dart';
import '../widgets/category_product_card.dart';

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
    _startBannerAutoSlide();
  }

  void _startBannerAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextBanner();
        _startBannerAutoSlide();
      }
    });
  }

  void _nextBanner() {
    if (_currentBannerIndex < 2) {
      _currentBannerIndex++;
    } else {
      _currentBannerIndex = 0;
    }
    _bannerController.animateToPage(
      _currentBannerIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroBannerSection(),
              _buildQuickStatsSection(),
              _buildCategoriesSection(),
              _buildFeaturedProductsSection(),
              _buildDealsSection(),
              _buildNewsletterSection(),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBannerSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final double height = isMobile ? 300 : 450;

        return Container(
          height: height,
          child: PageView(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            children: [
              _buildBannerSlide(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                title: 'Premium Quality Products',
                subtitle: 'Discover our curated collection',
                buttonText: 'Shop Now',
                isMobile: isMobile,
              ),
              _buildBannerSlide(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                title: 'Exclusive Deals',
                subtitle: 'Up to 70% off on selected items',
                buttonText: 'View Deals',
                isMobile: isMobile,
              ),
              _buildBannerSlide(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                title: 'Fast Delivery',
                subtitle: 'Free shipping on orders above ₹999',
                buttonText: 'Learn More',
                isMobile: isMobile,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerSlide({
    required Gradient gradient,
    required String title,
    required String subtitle,
    required String buttonText,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ Premium Collection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
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
                  subtitle,
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
                      onPressed: () => context.go('/products'),
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
                            buttonText,
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
            child: _buildPageIndicators(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
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

  Widget _buildQuickStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: Colors.white,
          child: Column(
            children: [
              Text(
                'Why Choose Us',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 32),
              isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard('50K+', 'Happy Customers',
                                    Icons.people_outline)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard('1000+', 'Products',
                                    Icons.inventory_2_outlined)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    '99%', 'Satisfaction', Icons.star_outline)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard('24/7', 'Support',
                                    Icons.support_agent_outlined)),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                            '50K+', 'Happy Customers', Icons.people_outline),
                        _buildStatCard(
                            '1000+', 'Products', Icons.inventory_2_outlined),
                        _buildStatCard(
                            '99%', 'Satisfaction', Icons.star_outline),
                        _buildStatCard(
                            '24/7', 'Support', Icons.support_agent_outlined),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

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
                    TextButton.icon(
                      onPressed: () => context.go('/categories'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View All'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF667EEA),
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
                      categoryProvider.categories.take(6).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: categories.length,
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
                  child: TextButton.icon(
                    onPressed: () => context.go('/categories'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('View All Categories'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF667EEA),
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

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: Colors.white,
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      productProvider.featuredProducts.take(6).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: isMobile ? 1.2 : 0.8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(product: product);
                    },
                  );
                },
              ),
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
                      child: const Text(
                        '⚡ LIMITED TIME',
                        style: TextStyle(
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
                      'Up to 70% off on selected items. Limited time only!',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/products'),
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
                          const Text(
                            'Shop Deals',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded),
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
                  child: const Icon(
                    Icons.local_offer_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsletterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

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
                'Stay Updated',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Get the latest updates on new products and exclusive offers',
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
                              hintText: 'Enter your email',
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
                                'Subscribe',
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
                                hintText: 'Enter your email',
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

  Widget _buildFooterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: const Color(0xFF1A365D),
          child: Column(
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterBrand(),
                    const SizedBox(height: 32),
                    _buildFooterLinks(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildFooterBrand()),
                    Expanded(flex: 3, child: _buildFooterLinks()),
                  ],
                ),
              const SizedBox(height: 32),
              Divider(color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2024 WellnessHub. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (!isMobile)
                    Row(
                      children: [
                        _buildSocialButton(Icons.facebook),
                        const SizedBox(width: 12),
                        _buildSocialButton(Icons.alternate_email),
                        const SizedBox(width: 12),
                        _buildSocialButton(Icons.message),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
            const Text(
              'WellnessHub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Your trusted partner for premium quality products. We deliver excellence with every purchase.',
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
                'Our Story',
                'Careers',
                'Press',
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
                'Cookie Policy',
                'Accessibility',
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
              'Our Story',
              'Careers',
              'Press',
            ]),
            _buildFooterColumn('Customer Care', [
              'Help Center',
              'Shipping Info',
              'Returns',
              'Track Order',
            ]),
            _buildFooterColumn('Legal', [
              'Privacy Policy',
              'Terms of Service',
              'Cookie Policy',
              'Accessibility',
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
                  // Handle navigation based on link
                  switch (link.toLowerCase()) {
                    case 'about us':
                      context.go('/about');
                      break;
                    case 'help center':
                      context.go('/help');
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

  Widget _buildSocialButton(IconData icon) {
    return GestureDetector(
      onTap: () {
        // Handle social media navigation
      },
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

// Custom Painter for Background Pattern
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
