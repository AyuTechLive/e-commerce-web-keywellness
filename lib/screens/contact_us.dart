// screens/contact_us_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/website_content_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../models/website_content.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Contact form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/contact'),
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
                          AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              );
            }

            final contactUs = provider.websiteConfig?.contactUs;
            if (contactUs == null || !contactUs.isEnabled) {
              return _buildPageNotAvailable();
            }

            return _buildPageContent(contactUs, provider.websiteConfig!);
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
            Icons.contact_mail_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Contact Us page is currently unavailable',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(PageContent contactUs, WebsiteConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(contactUs, isMobile),
              _buildMainContentSection(contactUs, isMobile),
              _buildContactFormSection(contactUs, isMobile),
              _buildQuickContactSection(contactUs, isMobile),
              _buildLocationSection(contactUs, isMobile),
              _buildFooterSection(config, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(PageContent contactUs, bool isMobile) {
    return Container(
      height: isMobile ? 300 : 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: contactUs.heroImageUrl?.isNotEmpty == true
            ? DecorationImage(
                image: NetworkImage(contactUs.heroImageUrl!),
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
                  Icon(
                    Icons.contact_mail_rounded,
                    size: isMobile ? 48 : 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contactUs.title,
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
                    contactUs.subtitle,
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

  Widget _buildMainContentSection(PageContent contactUs, bool isMobile) {
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
                contactUs.content,
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

  Widget _buildContactFormSection(PageContent contactUs, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'Send us a Message',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(isMobile ? 20 : 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (isMobile) ...[
                        _buildFormField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'Enter your email address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: 'Enter your phone number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: _subjectController,
                                label: 'Subject',
                                hint: 'Message subject',
                                icon: Icons.subject_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter subject';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isMobile) ...[
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _subjectController,
                          label: 'Subject',
                          hint: 'Message subject',
                          icon: Icons.subject_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter subject';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _messageController,
                        label: 'Message',
                        hint: 'Enter your message here...',
                        icon: Icons.message_outlined,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4AA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Send Message',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF00D4AA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildQuickContactSection(PageContent contactUs, bool isMobile) {
    if (contactUs.contactInfo == null) return const SizedBox.shrink();

    final contactInfo = contactUs.contactInfo!;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Quick Contact',
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
                const Color(0xFF00D4AA),
              ),
              _buildContactCard(
                Icons.phone_outlined,
                'Call Us',
                contactInfo.phone,
                'tel:${contactInfo.phone}',
                const Color(0xFF4FD1C7),
              ),
              _buildContactCard(
                Icons.location_on_outlined,
                'Visit Us',
                contactInfo.address,
                null,
                const Color(0xFF667EEA),
              ),
              _buildContactCard(
                Icons.access_time_outlined,
                'Working Hours',
                contactInfo.workingHours,
                null,
                const Color(0xFF764BA2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
      IconData icon, String title, String value, String? action, Color color) {
    return GestureDetector(
      onTap: action != null ? () => _launchUrl(action) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (action != null)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(PageContent contactUs, bool isMobile) {
    if (contactUs.keyPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Text(
            'Why Contact Us',
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
            itemCount: contactUs.keyPoints.length,
            itemBuilder: (context, index) {
              return _buildKeyPointCard(contactUs.keyPoints[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPointCard(String point, int index) {
    final colors = [
      [const Color(0xFF00D4AA), const Color(0xFF4FD1C7)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
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
      Icons.support_agent_outlined,
      Icons.schedule_outlined,
      Icons.verified_user_outlined,
      Icons.headset_mic_outlined,
      Icons.star_outline,
      Icons.thumb_up_outlined,
    ];
    return icons[index % icons.length];
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate form submission
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isSubmitting = false;
      });

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _subjectController.clear();
      _messageController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Message sent successfully! We\'ll get back to you soon.'),
          backgroundColor: Color(0xFF00D4AA),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// Custom Painter for Background Pattern (reusing from other pages)
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
