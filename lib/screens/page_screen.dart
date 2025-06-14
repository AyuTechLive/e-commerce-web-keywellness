// screens/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/website_content_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../models/website_content.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/about'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<WebsiteContentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              );
            }

            final aboutUs = provider.websiteConfig?.aboutUs;
            if (aboutUs == null || !aboutUs.isEnabled) {
              return _buildPageNotAvailable();
            }

            return _buildPageContent(aboutUs, provider.websiteConfig!);
          },
        ),
      ),
    );
  }

  Widget _buildPageNotAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'About Us page is currently unavailable',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(PageContent aboutUs, WebsiteConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(aboutUs, isMobile),
              _buildContentSection(aboutUs, isMobile),
              _buildKeyPointsSection(aboutUs, isMobile),
              if (aboutUs.contactInfo != null)
                _buildContactSection(aboutUs.contactInfo!, isMobile),
              _buildFooterSection(config, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(PageContent aboutUs, bool isMobile) {
    return Container(
      height: isMobile ? 300 : 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: aboutUs.heroImageUrl?.isNotEmpty == true
            ? DecorationImage(
                image: NetworkImage(aboutUs.heroImageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
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
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    aboutUs.title,
                    style: TextStyle(
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    aboutUs.subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(PageContent aboutUs, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              aboutUs.content,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                height: 1.8,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPointsSection(PageContent aboutUs, bool isMobile) {
    if (aboutUs.keyPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: const Color(0xFFF8F9FA),
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: isMobile ? 4 : 3,
            ),
            itemCount: aboutUs.keyPoints.length,
            itemBuilder: (context, index) {
              return _buildKeyPointCard(aboutUs.keyPoints[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPointCard(String point, int index) {
    final colors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF00D4AA), const Color(0xFF4FD1C7)],
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    ];

    final gradient = LinearGradient(
      colors: colors[index % colors.length],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[index % colors.length][0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForIndex(index),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              point,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    final icons = [
      Icons.verified_outlined,
      Icons.security_outlined,
      Icons.support_agent_outlined,
      Icons.local_shipping_outlined,
      Icons.star_outline,
      Icons.thumb_up_outlined,
    ];
    return icons[index % icons.length];
  }

  Widget _buildContactSection(ContactInfo contactInfo, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Get in Touch',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isMobile ? 4 : 2.5,
            children: [
              _buildContactCard(
                Icons.email_outlined,
                'Email Us',
                contactInfo.email,
                'mailto:${contactInfo.email}',
              ),
              _buildContactCard(
                Icons.phone_outlined,
                'Call Us',
                contactInfo.phone,
                'tel:${contactInfo.phone}',
              ),
              _buildContactCard(
                Icons.location_on_outlined,
                'Visit Us',
                contactInfo.address,
                null,
              ),
              _buildContactCard(
                Icons.access_time_outlined,
                'Working Hours',
                contactInfo.workingHours,
                null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
      IconData icon, String title, String value, String? action) {
    return GestureDetector(
      onTap: action != null ? () => _launchUrl(action) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A365D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection(WebsiteConfig config, bool isMobile) {
    final siteName = config.siteName;
    final logoUrl = config.logoUrl;
    final description = config.description ??
        'Your trusted partner for premium quality products. We deliver excellence with every purchase and amazing deals.';
    final footerText = config.footerText;
    final socialMedia = config.socialMedia;

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
                    child: _buildFooterBrand(siteName, logoUrl, description)),
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
                  _buildSocialButton(Icons.camera_alt, socialMedia.instagram),
                if (socialMedia.twitter.isNotEmpty)
                  _buildSocialButton(
                      Icons.alternate_email, socialMedia.twitter),
                if (socialMedia.whatsapp.isNotEmpty)
                  _buildSocialButton(
                      Icons.message, 'https://wa.me/${socialMedia.whatsapp}'),
                if (socialMedia.email.isNotEmpty)
                  _buildSocialButton(
                      Icons.email, 'mailto:${socialMedia.email}'),
              ].where((widget) => widget != null).cast<Widget>().toList(),
            ),
          ],
        ],
      ),
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
                'Our Story',
                'Sale Products',
                'Careers',
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
              // 'Our Story',
              'Sale Products',
              // 'Careers',
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
              'Refund Policy',
              // 'Accessibility',
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
                    case 'help center':
                      context.go('/contact-us');
                      break;
                    case 'privacy policy':
                      context.go('/privacy');
                      break;
                    case 'shipping info':
                      context.go('/profile');
                      break;
                    case 'returns':
                      context.go('/profile');
                      break;
                    case 'track order':
                      context.go('/profile');
                      break;
                    case 'terms of service':
                      context.go('/terms');
                      break;
                    case 'refund policy':
                      context.go('/refund');
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// screens/refund_policy_screen.dart
class RefundPolicyScreen extends StatefulWidget {
  const RefundPolicyScreen({Key? key}) : super(key: key);

  @override
  State<RefundPolicyScreen> createState() => _RefundPolicyScreenState();
}

class _RefundPolicyScreenState extends State<RefundPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebsiteContentProvider>(context, listen: false)
          .loadWebsiteConfig();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/refund'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<WebsiteContentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              );
            }

            final refundPolicy = provider.websiteConfig?.refundPolicy;
            if (refundPolicy == null || !refundPolicy.isEnabled) {
              return _buildPageNotAvailable();
            }

            return _buildPageContent(refundPolicy, provider.websiteConfig!);
          },
        ),
      ),
    );
  }

  Widget _buildPageNotAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Refund Policy is currently unavailable',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(PageContent refundPolicy, WebsiteConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(refundPolicy, isMobile),
              _buildContentSection(refundPolicy, isMobile),
              _buildKeyPointsSection(refundPolicy, isMobile),
              _buildFooterSection(config, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(PageContent refundPolicy, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: isMobile ? 48 : 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    refundPolicy.title,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    refundPolicy.subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(PageContent refundPolicy, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: ${_formatDate(refundPolicy.lastUpdated)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                refundPolicy.content,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  height: 1.8,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPointsSection(PageContent refundPolicy, bool isMobile) {
    if (refundPolicy.keyPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Text(
            'Refund Policy Highlights',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 24),
          ...refundPolicy.keyPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooterSection(WebsiteConfig config, bool isMobile) {
    final siteName = config.siteName;
    final logoUrl = config.logoUrl;
    final description = config.description ??
        'Your trusted partner for premium quality products. We deliver excellence with every purchase and amazing deals.';
    final footerText = config.footerText;
    final socialMedia = config.socialMedia;

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
                    child: _buildFooterBrand(siteName, logoUrl, description)),
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
                  _buildSocialButton(Icons.camera_alt, socialMedia.instagram),
                if (socialMedia.twitter.isNotEmpty)
                  _buildSocialButton(
                      Icons.alternate_email, socialMedia.twitter),
                if (socialMedia.whatsapp.isNotEmpty)
                  _buildSocialButton(
                      Icons.message, 'https://wa.me/${socialMedia.whatsapp}'),
                if (socialMedia.email.isNotEmpty)
                  _buildSocialButton(
                      Icons.email, 'mailto:${socialMedia.email}'),
              ].where((widget) => widget != null).cast<Widget>().toList(),
            ),
          ],
        ],
      ),
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
                'Our Story',
                'Sale Products',
                'Careers',
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
              'Sale Products',
              'Careers',
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
                  switch (link.toLowerCase()) {
                    case 'about us':
                      context.go('/about');
                      break;
                    case 'sale products':
                      context.go('/products?filter=sale');
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// Custom Painter for Background Pattern (shared by all pages)
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

void _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// screens/privacy_policy_screen.dart
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebsiteContentProvider>(context, listen: false)
          .loadWebsiteConfig();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/privacy'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<WebsiteContentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              );
            }

            final privacyPolicy = provider.websiteConfig?.privacyPolicy;
            if (privacyPolicy == null || !privacyPolicy.isEnabled) {
              return _buildPageNotAvailable();
            }

            return _buildPageContent(privacyPolicy, provider.websiteConfig!);
          },
        ),
      ),
    );
  }

  Widget _buildPageNotAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Privacy Policy is currently unavailable',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(PageContent privacyPolicy, WebsiteConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(privacyPolicy, isMobile),
              _buildContentSection(privacyPolicy, isMobile),
              _buildKeyPointsSection(privacyPolicy, isMobile),
              _buildFooterSection(config, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(PageContent privacyPolicy, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: isMobile ? 48 : 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    privacyPolicy.title,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    privacyPolicy.subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(PageContent privacyPolicy, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: ${_formatDate(privacyPolicy.lastUpdated)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                privacyPolicy.content,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  height: 1.8,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPointsSection(PageContent privacyPolicy, bool isMobile) {
    if (privacyPolicy.keyPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Text(
            'Key Privacy Points',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 24),
          ...privacyPolicy.keyPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooterSection(WebsiteConfig config, bool isMobile) {
    final siteName = config.siteName;
    final logoUrl = config.logoUrl;
    final description = config.description ??
        'Your trusted partner for premium quality products. We deliver excellence with every purchase and amazing deals.';
    final footerText = config.footerText;
    final socialMedia = config.socialMedia;

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
                    child: _buildFooterBrand(siteName, logoUrl, description)),
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
                  _buildSocialButton(Icons.camera_alt, socialMedia.instagram),
                if (socialMedia.twitter.isNotEmpty)
                  _buildSocialButton(
                      Icons.alternate_email, socialMedia.twitter),
                if (socialMedia.whatsapp.isNotEmpty)
                  _buildSocialButton(
                      Icons.message, 'https://wa.me/${socialMedia.whatsapp}'),
                if (socialMedia.email.isNotEmpty)
                  _buildSocialButton(
                      Icons.email, 'mailto:${socialMedia.email}'),
              ].where((widget) => widget != null).cast<Widget>().toList(),
            ),
          ],
        ],
      ),
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
                'Our Story',
                'Sale Products',
                'Careers',
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
              'Sale Products',
              'Careers',
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
                  switch (link.toLowerCase()) {
                    case 'about us':
                      context.go('/about');
                      break;
                    case 'sale products':
                      context.go('/products?filter=sale');
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// screens/terms_conditions_screen.dart
class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebsiteContentProvider>(context, listen: false)
          .loadWebsiteConfig();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/terms'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<WebsiteContentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              );
            }

            final termsConditions = provider.websiteConfig?.termsConditions;
            if (termsConditions == null || !termsConditions.isEnabled) {
              return _buildPageNotAvailable();
            }

            return _buildPageContent(termsConditions, provider.websiteConfig!);
          },
        ),
      ),
    );
  }

  Widget _buildPageNotAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Terms & Conditions are currently unavailable',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(PageContent termsConditions, WebsiteConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(termsConditions, isMobile),
              _buildContentSection(termsConditions, isMobile),
              _buildKeyPointsSection(termsConditions, isMobile),
              _buildFooterSection(config, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(PageContent termsConditions, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gavel_outlined,
                    size: isMobile ? 48 : 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    termsConditions.title,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    termsConditions.subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(PageContent termsConditions, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: ${_formatDate(termsConditions.lastUpdated)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                termsConditions.content,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  height: 1.8,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildKeyPointsSection(PageContent termsConditions, bool isMobile) {
    if (termsConditions.keyPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Text(
            'Key Terms Summary',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 24),
          ...termsConditions.keyPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooterSection(WebsiteConfig config, bool isMobile) {
    final siteName = config.siteName;
    final logoUrl = config.logoUrl;
    final description = config.description ??
        'Your trusted partner for premium quality products. We deliver excellence with every purchase and amazing deals.';
    final footerText = config.footerText;
    final socialMedia = config.socialMedia;

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
                    child: _buildFooterBrand(siteName, logoUrl, description)),
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
                  _buildSocialButton(Icons.camera_alt, socialMedia.instagram),
                if (socialMedia.twitter.isNotEmpty)
                  _buildSocialButton(
                      Icons.alternate_email, socialMedia.twitter),
                if (socialMedia.whatsapp.isNotEmpty)
                  _buildSocialButton(
                      Icons.message, 'https://wa.me/${socialMedia.whatsapp}'),
                if (socialMedia.email.isNotEmpty)
                  _buildSocialButton(
                      Icons.email, 'mailto:${socialMedia.email}'),
              ].where((widget) => widget != null).cast<Widget>().toList(),
            ),
          ],
        ],
      ),
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
                'Our Story',
                'Sale Products',
                'Careers',
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
              'Sale Products',
              'Careers',
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
                  switch (link.toLowerCase()) {
                    case 'about us':
                      context.go('/about');
                      break;
                    case 'sale products':
                      context.go('/products?filter=sale');
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
}
