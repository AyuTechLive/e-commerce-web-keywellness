// providers/website_content_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/website_content.dart';

class WebsiteContentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WebsiteConfig? _websiteConfig;
  bool _isLoading = false;
  String? _error;

  WebsiteConfig? get websiteConfig => _websiteConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get website configuration
  Future<void> loadWebsiteConfig() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final doc =
          await _firestore.collection('website_config').doc('main').get();

      if (doc.exists) {
        _websiteConfig = WebsiteConfig.fromMap(doc.data()!, doc.id);
      } else {
        // Create default configuration if it doesn't exist
        await _createDefaultConfig();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create default configuration with page content
  Future<void> _createDefaultConfig() async {
    final defaultConfig = WebsiteConfig(
      id: 'main',
      siteName: 'WellnessHub',
      logoUrl: '',
      tagline: 'Your Wellness Partner',
      description:
          'Premium quality products for your health and wellness journey',
      banners: [
        BannerItem(
          id: 'banner1',
          title: 'Premium Quality Products',
          subtitle: 'Discover our curated collection',
          buttonText: 'Shop Now',
          buttonAction: '/products',
          gradientColors: ['#667EEA', '#764BA2'],
          badgeText: 'Premium Collection',
          badgeIcon: '✨',
          order: 1,
        ),
        BannerItem(
          id: 'banner2',
          title: 'Mega Sale Now Live!',
          subtitle: 'Up to 70% off on selected items',
          buttonText: 'Shop Sale',
          buttonAction: '/products?filter=sale',
          gradientColors: ['#FF6B6B', '#FFE66D'],
          badgeText: 'Limited Time Only',
          badgeIcon: '🔥',
          order: 2,
        ),
        BannerItem(
          id: 'banner3',
          title: 'Fast Delivery',
          subtitle: 'Free shipping on orders above ₹500',
          buttonText: 'Learn More',
          buttonAction: '/about',
          gradientColors: ['#4ECDC4', '#44A08D'],
          badgeText: 'Free Shipping',
          badgeIcon: '🚚',
          order: 3,
        ),
      ],
      stats: [
        StatItem(
          id: 'stat1',
          number: '50K+',
          label: 'Happy Customers',
          iconName: 'people_outline',
          gradientColors: ['#667EEA', '#764BA2'],
          order: 1,
        ),
        StatItem(
          id: 'stat2',
          number: '1000+',
          label: 'Products',
          iconName: 'inventory_2_outlined',
          gradientColors: ['#667EEA', '#764BA2'],
          order: 2,
        ),
        StatItem(
          id: 'stat3',
          number: '99%',
          label: 'Satisfaction',
          iconName: 'star_outline',
          gradientColors: ['#667EEA', '#764BA2'],
          order: 3,
        ),
        StatItem(
          id: 'stat4',
          number: '24/7',
          label: 'Support',
          iconName: 'support_agent_outlined',
          gradientColors: ['#667EEA', '#764BA2'],
          order: 4,
        ),
      ],
      socialMedia: SocialMediaLinks(
        facebook: 'https://facebook.com/wellnesshub',
        instagram: 'https://instagram.com/wellnesshub',
        twitter: 'https://twitter.com/wellnesshub',
        email: 'contact@wellnesshub.com',
        phone: '+91-9876543210',
        whatsapp: '+91-9876543210',
      ),
      footerText: '© 2024 WellnessHub. All rights reserved.',
      aboutUs: PageContent(
        title: 'About WellnessHub',
        subtitle: 'Your trusted partner in health and wellness',
        content:
            '''Welcome to WellnessHub, your premier destination for quality health and wellness products. Founded with the mission to make healthy living accessible and affordable for everyone, we have been serving our community with dedication and care.

Our Story
WellnessHub was born out of a simple belief: everyone deserves access to high-quality health products without compromising on affordability or authenticity. Our founders, passionate about wellness and customer care, started this journey to bridge the gap between quality healthcare products and the people who need them.

Our Mission
We are committed to providing our customers with authentic, high-quality health and wellness products sourced from trusted manufacturers. Our rigorous quality control processes ensure that every product that reaches you meets our strict standards of excellence.

Why Choose Us?
At WellnessHub, we understand that your health is your most valuable asset. That's why we go above and beyond to ensure that you receive only the best products and services. Our team of experts carefully curates each product in our inventory, ensuring authenticity and effectiveness.

Our Promise
We promise to continue serving you with the same dedication and care that has made us a trusted name in the wellness industry. Your health and satisfaction remain our top priorities.''',
        keyPoints: [
          'Premium quality products from trusted brands',
          'Rigorous quality control and authenticity verification',
          'Expert customer support and guidance',
          'Fast and secure delivery nationwide',
          'Competitive pricing and regular offers',
          '100% genuine products guarantee'
        ],
        contactInfo: ContactInfo(
          email: 'info@wellnesshub.com',
          phone: '+91-9876543210',
          address: '123 Wellness Street, Health City, HC 12345',
          workingHours: 'Monday to Saturday: 9 AM - 8 PM\nSunday: 10 AM - 6 PM',
        ),
        lastUpdated: DateTime.now(),
      ),
      privacyPolicy: PageContent(
        title: 'Privacy Policy',
        subtitle: 'How we protect and handle your personal information',
        content:
            '''At WellnessHub, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website or use our services.

Information We Collect
We may collect information about you in a variety of ways. The information we may collect includes:

Personal Data: When you create an account, make a purchase, or contact us, we may collect personally identifiable information, such as your name, shipping address, email address, and telephone number.

Derivative Data: Information our servers automatically collect when you access our website, such as your IP address, browser type, operating system, access times, and the pages you view.

Financial Data: Financial information, such as data related to your payment method (e.g., valid credit card number, card brand, expiration date) that we may collect when you purchase, order, return, exchange, or request information about our services.

Use of Your Information
Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via our website to:

- Create and manage your account
- Process your transactions and send you related information
- Email you regarding your account or order
- Deliver targeted advertising, coupons, newsletters, and promotions
- Request feedback and contact you about your use of our website
- Resolve disputes and troubleshoot problems
- Respond to product and customer service requests
- Send you a newsletter
- Improve our website and services

Disclosure of Your Information
We may share information we have collected about you in certain situations. Your information may be disclosed as follows:

By Law or to Protect Rights: If we believe the release of information about you is necessary to respond to legal process, to investigate or remedy potential violations of our policies, or to protect the rights, property, and safety of others.

Business Transfers: We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business.

Third-Party Service Providers: We may share your information with third parties that perform services for us or on our behalf, including payment processing, data analysis, email delivery, hosting services, customer service, and marketing assistance.

Security of Your Information
We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable.

Contact Us
If you have questions or comments about this Privacy Policy, please contact us at:

Email: privacy@wellnesshub.com
Phone: +91-9876543210
Address: 123 Wellness Street, Health City, HC 12345''',
        keyPoints: [
          'We collect only necessary information for service delivery',
          'Your data is secured with industry-standard encryption',
          'We never sell your personal information to third parties',
          'You have full control over your data and privacy settings',
          'Regular security audits ensure data protection',
          'Transparent communication about data usage'
        ],
        lastUpdated: DateTime.now(),
      ),
      termsConditions: PageContent(
        title: 'Terms and Conditions',
        subtitle: 'Terms of service for using WellnessHub platform',
        content:
            '''Welcome to WellnessHub. These terms and conditions outline the rules and regulations for the use of WellnessHub's Website, located at wellnesshub.com.

By accessing this website, we assume you accept these terms and conditions. Do not continue to use WellnessHub if you do not agree to take all of the terms and conditions stated on this page.

Definitions
"Company" (or "we" or "us" or "our") refers to WellnessHub.
"You" refers to the individual accessing or using the website.
"Service" refers to the website and services provided by WellnessHub.

Use License
Permission is granted to temporarily download one copy of the materials on WellnessHub's website for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
- Modify or copy the materials
- Use the materials for any commercial purpose or for any public display
- Attempt to reverse engineer any software contained on the website
- Remove any copyright or other proprietary notations from the materials

Account Terms
To access some features of the service, you must register for an account. When you create an account, you must provide information that is accurate, complete, and current at all times.

You are responsible for safeguarding the password and for all activities that occur under your account. You agree not to disclose your password to any third party.

Product Information
We strive to provide accurate product information, including descriptions, images, and pricing. However, we do not warrant that product descriptions or other content is accurate, complete, reliable, current, or error-free.

Pricing and Payment
All prices are listed in Indian Rupees (INR) and are subject to change without notice. Payment is due upon completion of your order. We accept various payment methods as displayed during checkout.

Shipping and Delivery
We aim to process and ship orders within 1-2 business days. Delivery times may vary based on location and product availability. Shipping costs are calculated at checkout.

Returns and Refunds
We accept returns within 7 days of delivery for most products in original condition. Certain products may have different return policies due to health and safety regulations. Please refer to our Refund Policy for detailed information.

Limitation of Liability
In no event shall WellnessHub or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on WellnessHub's website.

Governing Law
These terms and conditions are governed by and construed in accordance with the laws of India, and you irrevocably submit to the exclusive jurisdiction of the courts in that state or location.

Changes to Terms
We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting. Your continued use of the service constitutes acceptance of the modified terms.

Contact Information
For questions about these Terms and Conditions, please contact us:

Email: legal@wellnesshub.com
Phone: +91-9876543210
Address: 123 Wellness Street, Health City, HC 12345''',
        keyPoints: [
          'Fair and transparent terms for all users',
          'Clear guidelines for account usage and responsibilities',
          'Comprehensive product and pricing policies',
          'Detailed shipping and delivery information',
          'Straightforward return and refund procedures',
          'Legal protections for both parties'
        ],
        lastUpdated: DateTime.now(),
      ),
      refundPolicy: PageContent(
        title: 'Refund Policy',
        subtitle: 'Our commitment to customer satisfaction and fair returns',
        content:
            '''At WellnessHub, your satisfaction is our priority. We strive to provide high-quality products and excellent service. This Refund Policy outlines the terms and conditions for returns, exchanges, and refunds.

Return Eligibility
We accept returns for most products within 7 days of delivery, provided they meet the following conditions:

- Products must be in their original condition and packaging
- Items should be unused and in resalable condition
- Original receipt or proof of purchase is required
- Products must not be expired or near expiry

Non-Returnable Items
For health and safety reasons, certain items cannot be returned:
- Opened personal care products and cosmetics
- Expired products
- Prescription medications
- Custom or personalized items
- Perishable goods

Return Process
To initiate a return, please follow these steps:

1. Contact our customer service team within 7 days of delivery
2. Provide your order number and reason for return
3. Receive return authorization and shipping instructions
4. Package items securely in original packaging
5. Ship items using provided return label

Refund Timeline
Once we receive your returned items, our team will inspect them within 2-3 business days. Approved refunds will be processed as follows:

- Credit/Debit Card: 5-7 business days
- UPI/Digital Wallets: 1-3 business days
- Bank Transfer: 3-5 business days
- Store Credit: Immediate

Refund Methods
Refunds will be processed using the same payment method used for the original purchase. In some cases, we may offer store credit as an alternative option.

Exchange Policy
We offer exchanges for defective or damaged products within 7 days of delivery. Exchanges are subject to product availability. If the exact product is unavailable, we will offer:

- A similar product of equal or higher value
- Store credit for the full amount
- Complete refund

Damaged or Defective Products
If you receive a damaged or defective product:

1. Contact us immediately upon delivery
2. Provide photos of the damaged item
3. We will arrange immediate replacement or refund
4. Return shipping costs will be covered by us

Cancellation Policy
Orders can be cancelled free of charge before they are shipped. Once shipped, standard return policy applies.

Shipping Costs
- Return shipping costs are borne by the customer unless the product is defective or we made an error
- We provide prepaid return labels for defective products
- Original shipping charges are non-refundable except in cases of our error

Partial Refunds
Partial refunds may be issued in the following cases:
- Items not in original condition
- Items damaged by customer misuse
- Items missing parts not due to our error

Customer Service
Our customer service team is available to assist with returns and refunds:

Email: returns@wellnesshub.com
Phone: +91-9876543210
Hours: Monday to Saturday, 9 AM - 8 PM

Policy Updates
This refund policy may be updated from time to time. Changes will be posted on our website with the effective date. Continued use of our services constitutes acceptance of the updated policy.

Contact Us
For any questions about our refund policy, please contact us:

Email: support@wellnesshub.com
Phone: +91-9876543210
Address: 123 Wellness Street, Health City, HC 12345''',
        keyPoints: [
          '7-day return window for most products',
          'Free returns for defective or damaged items',
          'Multiple refund methods available',
          'Quick processing within 2-3 business days',
          'Fair exchange policy for unavailable items',
          '24/7 customer support for return assistance'
        ],
        lastUpdated: DateTime.now(),
      ),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('website_config')
        .doc('main')
        .set(defaultConfig.toMap());
    _websiteConfig = defaultConfig;
  }

  // Update website configuration
  Future<String?> updateWebsiteConfig(WebsiteConfig config) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('website_config')
          .doc('main')
          .set(config.toMap());
      _websiteConfig = config;

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Update site branding
  Future<String?> updateSiteBranding({
    required String siteName,
    required String logoUrl,
    required String tagline,
    required String description,
    required String footerText,
  }) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: siteName,
      logoUrl: logoUrl,
      tagline: tagline,
      description: description,
      banners: _websiteConfig!.banners,
      stats: _websiteConfig!.stats,
      socialMedia: _websiteConfig!.socialMedia,
      footerText: footerText,
      aboutUs: _websiteConfig!.aboutUs,
      privacyPolicy: _websiteConfig!.privacyPolicy,
      termsConditions: _websiteConfig!.termsConditions,
      refundPolicy: _websiteConfig!.refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Update page content
  Future<String?> updatePageContent({
    required String pageType,
    required PageContent content,
  }) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    PageContent aboutUs = _websiteConfig!.aboutUs;
    PageContent privacyPolicy = _websiteConfig!.privacyPolicy;
    PageContent termsConditions = _websiteConfig!.termsConditions;
    PageContent refundPolicy = _websiteConfig!.refundPolicy;

    switch (pageType) {
      case 'aboutUs':
        aboutUs = content;
        break;
      case 'privacyPolicy':
        privacyPolicy = content;
        break;
      case 'termsConditions':
        termsConditions = content;
        break;
      case 'refundPolicy':
        refundPolicy = content;
        break;
      default:
        return 'Invalid page type';
    }

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: _websiteConfig!.siteName,
      logoUrl: _websiteConfig!.logoUrl,
      tagline: _websiteConfig!.tagline,
      description: _websiteConfig!.description,
      banners: _websiteConfig!.banners,
      stats: _websiteConfig!.stats,
      socialMedia: _websiteConfig!.socialMedia,
      footerText: _websiteConfig!.footerText,
      aboutUs: aboutUs,
      privacyPolicy: privacyPolicy,
      termsConditions: termsConditions,
      refundPolicy: refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Add or update banner
  Future<String?> saveBanner(BannerItem banner) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    final banners = List<BannerItem>.from(_websiteConfig!.banners);
    final existingIndex = banners.indexWhere((b) => b.id == banner.id);

    if (existingIndex >= 0) {
      banners[existingIndex] = banner;
    } else {
      banners.add(banner);
    }

    // Sort by order
    banners.sort((a, b) => a.order.compareTo(b.order));

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: _websiteConfig!.siteName,
      logoUrl: _websiteConfig!.logoUrl,
      tagline: _websiteConfig!.tagline,
      description: _websiteConfig!.description,
      banners: banners,
      stats: _websiteConfig!.stats,
      socialMedia: _websiteConfig!.socialMedia,
      footerText: _websiteConfig!.footerText,
      aboutUs: _websiteConfig!.aboutUs,
      privacyPolicy: _websiteConfig!.privacyPolicy,
      termsConditions: _websiteConfig!.termsConditions,
      refundPolicy: _websiteConfig!.refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Delete banner
  Future<String?> deleteBanner(String bannerId) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    final banners =
        _websiteConfig!.banners.where((b) => b.id != bannerId).toList();

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: _websiteConfig!.siteName,
      logoUrl: _websiteConfig!.logoUrl,
      tagline: _websiteConfig!.tagline,
      description: _websiteConfig!.description,
      banners: banners,
      stats: _websiteConfig!.stats,
      socialMedia: _websiteConfig!.socialMedia,
      footerText: _websiteConfig!.footerText,
      aboutUs: _websiteConfig!.aboutUs,
      privacyPolicy: _websiteConfig!.privacyPolicy,
      termsConditions: _websiteConfig!.termsConditions,
      refundPolicy: _websiteConfig!.refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Add or update stat
  Future<String?> saveStat(StatItem stat) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    final stats = List<StatItem>.from(_websiteConfig!.stats);
    final existingIndex = stats.indexWhere((s) => s.id == stat.id);

    if (existingIndex >= 0) {
      stats[existingIndex] = stat;
    } else {
      stats.add(stat);
    }

    // Sort by order
    stats.sort((a, b) => a.order.compareTo(b.order));

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: _websiteConfig!.siteName,
      logoUrl: _websiteConfig!.logoUrl,
      tagline: _websiteConfig!.tagline,
      description: _websiteConfig!.description,
      banners: _websiteConfig!.banners,
      stats: stats,
      socialMedia: _websiteConfig!.socialMedia,
      footerText: _websiteConfig!.footerText,
      aboutUs: _websiteConfig!.aboutUs,
      privacyPolicy: _websiteConfig!.privacyPolicy,
      termsConditions: _websiteConfig!.termsConditions,
      refundPolicy: _websiteConfig!.refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Delete stat
  Future<String?> deleteStat(String statId) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    final stats = _websiteConfig!.stats.where((s) => s.id != statId).toList();

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: _websiteConfig!.siteName,
      logoUrl: _websiteConfig!.logoUrl,
      tagline: _websiteConfig!.tagline,
      description: _websiteConfig!.description,
      banners: _websiteConfig!.banners,
      stats: stats,
      socialMedia: _websiteConfig!.socialMedia,
      footerText: _websiteConfig!.footerText,
      aboutUs: _websiteConfig!.aboutUs,
      privacyPolicy: _websiteConfig!.privacyPolicy,
      termsConditions: _websiteConfig!.termsConditions,
      refundPolicy: _websiteConfig!.refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Update social media links
  Future<String?> updateSocialMedia(SocialMediaLinks socialMedia) async {
    if (_websiteConfig == null) return 'Website config not loaded';

    final updatedConfig = WebsiteConfig(
      id: _websiteConfig!.id,
      siteName: _websiteConfig!.siteName,
      logoUrl: _websiteConfig!.logoUrl,
      tagline: _websiteConfig!.tagline,
      description: _websiteConfig!.description,
      banners: _websiteConfig!.banners,
      stats: _websiteConfig!.stats,
      socialMedia: socialMedia,
      footerText: _websiteConfig!.footerText,
      aboutUs: _websiteConfig!.aboutUs,
      privacyPolicy: _websiteConfig!.privacyPolicy,
      termsConditions: _websiteConfig!.termsConditions,
      refundPolicy: _websiteConfig!.refundPolicy,
      updatedAt: DateTime.now(),
    );

    return await updateWebsiteConfig(updatedConfig);
  }

  // Helper method to get active banners
  List<BannerItem> get activeBanners {
    if (_websiteConfig == null) return [];
    return _websiteConfig!.banners.where((banner) => banner.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // Helper method to get active stats
  List<StatItem> get activeStats {
    if (_websiteConfig == null) return [];
    return _websiteConfig!.stats.where((stat) => stat.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
