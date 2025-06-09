// screens/home_screen.dart - Mobile Responsive Version
import 'package:flutter/material.dart';
import 'package:keiwaywellness/widgets/category_product_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              _buildSearchSection(),
              _buildStatsSection(),
              _buildCategoriesSection(),
              _buildFeaturedProductsSection(),
              _buildNewsletterSection(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Container(
          height: isMobile ? 350 : (isTablet ? 400 : 500),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A365D), // Deep navy blue
                Color(0xFF2B6CB0), // Rich blue
                Color(0xFF3182CE), // Bright blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Geometric background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: GeometricPatternPainter(),
                ),
              ),
              // Content overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Hero image - Only show on larger screens
              if (!isMobile)
                Positioned(
                  right: -50,
                  top: 50,
                  bottom: 50,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              // Hero content
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: isMobile ? 0 : MediaQuery.of(context).size.width * 0.4,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 20 : (isTablet ? 30 : 50)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✨ Premium Quality',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5568),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      Text(
                        isMobile
                            ? 'Elevate Your\nWellness'
                            : 'Elevate Your\nWellness Journey',
                        style: TextStyle(
                          fontSize: isMobile ? 36 : (isTablet ? 44 : 52),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 20),
                      Text(
                        isMobile
                            ? 'Discover wellness products that transform your daily routine.'
                            : 'Discover scientifically-backed wellness products\nthat transform your daily routine into a path\ntoward optimal health and vitality.',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 18,
                          color: const Color(0xFFE2E8F0),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 40),
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Scroll to products section
                              Scrollable.ensureVisible(
                                context,
                                duration: const Duration(milliseconds: 500),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4AA),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 24 : 32,
                                  vertical: isMobile ? 14 : 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFF00D4AA).withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Shop Collection',
                                  style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 18),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? 0 : 16,
                            height: isMobile ? 12 : 0,
                          ),
                          OutlinedButton(
                            onPressed: () {
                              context.go('/about');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 24 : 24,
                                  vertical: isMobile ? 14 : 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Learn More',
                              style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 50, vertical: isMobile ? 30 : 60),
          color: const Color(0xFFFAFBFC),
          child: Center(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: isMobile ? double.infinity : 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isMobile
                      ? 'Search products...'
                      : 'Search wellness products, supplements, and more...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF00D4AA),
                      size: 24,
                    ),
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          context.go('/search?q=${_searchController.text}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    context.go('/search?q=$value');
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 50, vertical: isMobile ? 30 : 40),
          color: Colors.white,
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatItem('50K+', 'Happy Customers',
                                Icons.people_outline)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildStatItem('1000+', 'Premium Products',
                                Icons.inventory_2_outlined)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatItem('99%', 'Satisfaction Rate',
                                Icons.star_outline)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildStatItem('24/7', 'Customer Support',
                                Icons.support_agent_outlined)),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                        '50K+', 'Happy Customers', Icons.people_outline),
                    _buildStatItem('1000+', 'Premium Products',
                        Icons.inventory_2_outlined),
                    _buildStatItem(
                        '99%', 'Satisfaction Rate', Icons.star_outline),
                    _buildStatItem('24/7', 'Customer Support',
                        Icons.support_agent_outlined),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStatItem(String number, String label, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 200;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: const Color(0xFF00D4AA), size: isMobile ? 24 : 32),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              number,
              style: TextStyle(
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A365D),
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 50),
          color: const Color(0xFFFAFBFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop by Category',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A365D),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 8),
                      Text(
                        'Explore our curated collection of wellness essentials',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 0),
                  TextButton.icon(
                    onPressed: () {
                      context.go('/categories');
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00D4AA),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 40),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                      crossAxisSpacing: isMobile ? 12 : 24,
                      mainAxisSpacing: isMobile ? 12 : 24,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: categoryProvider.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryProvider.categories[index];
                      return CategoryCard(category: category);
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

  Widget _buildFeaturedProductsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 50),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Products',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A365D),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 8),
                      Text(
                        'Hand-picked premium products for your wellness journey',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 0),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'New Arrivals',
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 40),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                      crossAxisSpacing: isMobile ? 0 : 24,
                      mainAxisSpacing: isMobile ? 16 : 24,
                      childAspectRatio: isMobile ? 1.2 : 0.75,
                    ),
                    itemCount: productProvider.featuredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.featuredProducts[index];
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

  Widget _buildNewsletterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          margin: EdgeInsets.all(isMobile ? 16 : 50),
          padding: EdgeInsets.all(isMobile ? 30 : 60),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            children: [
              Expanded(
                flex: isMobile ? 0 : 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Updated',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      'Get the latest wellness tips, product updates, and exclusive offers delivered to your inbox.',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(0xFFE2E8F0),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 32),
                    Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 0 : 16,
                          height: isMobile ? 12 : 0,
                        ),
                        SizedBox(
                          width: isMobile ? double.infinity : null,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4AA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Subscribe',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 40),
                Expanded(
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      size: 80,
                      color: Colors.white,
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

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 50),
          color: const Color(0xFF1A365D),
          child: Column(
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wellness Store',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your trusted partner in the journey toward optimal wellness. We provide premium, scientifically-backed products that enhance your daily life.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildSocialButton(Icons.facebook, () {}),
                            const SizedBox(width: 12),
                            _buildSocialButton(Icons.abc_sharp, () {}),
                            const SizedBox(width: 12),
                            _buildSocialButton(Icons.abc, () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 40),
                  if (isMobile) const SizedBox(height: 32),
                  if (isMobile)
                    Column(
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
                          'Returns & Exchanges',
                          'Track Your Order',
                        ]),
                        const SizedBox(height: 24),
                        _buildFooterColumn('Legal', [
                          'Privacy Policy',
                          'Terms of Service',
                          'Cookie Policy',
                          'Accessibility',
                        ]),
                      ],
                    )
                  else
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            'Returns & Exchanges',
                            'Track Your Order',
                          ]),
                          _buildFooterColumn('Legal', [
                            'Privacy Policy',
                            'Terms of Service',
                            'Cookie Policy',
                            'Accessibility',
                          ]),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 32 : 40),
              Divider(color: Colors.white.withOpacity(0.2)),
              SizedBox(height: isMobile ? 16 : 24),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2025 Wellness Store. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (isMobile) const SizedBox(height: 8),
                  Row(
                    mainAxisSize:
                        isMobile ? MainAxisSize.min : MainAxisSize.max,
                    children: [
                      Text(
                        'Made with ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFF00D4AA),
                        size: 16,
                      ),
                      Text(
                        ' for your wellness',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildFooterColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: () {
                  // Navigate based on link
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
                      // Handle other links
                      break;
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.8),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  link,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

// Custom painter for geometric background pattern
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw geometric shapes
    for (int i = 0; i < 20; i++) {
      final x = (i * size.width / 10) % size.width;
      final y = (i * size.height / 15) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        20 + (i % 3) * 10,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
