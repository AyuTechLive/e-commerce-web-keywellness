// providers/admin_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/website_content.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Categories Management
  Future<String?> addCategory({
    required String name,
    required String imageUrl,
    required String description,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final category = Category(
        id: '',
        name: name,
        imageUrl: imageUrl,
        description: description,
      );

      await _firestore.collection('categories').add(category.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
    required String description,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final category = Category(
        id: id,
        name: name,
        imageUrl: imageUrl,
        description: description,
      );

      await _firestore
          .collection('categories')
          .doc(id)
          .update(category.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('categories').doc(id).delete();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Products Management
  Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    required String imageUrl,
    required String categoryId,
    required bool inStock,
    required List<String> tags,
    required double rating,
    required int reviewCount,
    bool hasDiscount = false,
    double? discountPercentage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final product = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        categoryId: categoryId,
        inStock: inStock,
        tags: tags,
        rating: rating,
        reviewCount: reviewCount,
        hasDiscount: hasDiscount,
        discountPercentage: discountPercentage,
      );

      // Add to Realtime Database
      await _database.child('products').push().set(product.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    required String imageUrl,
    required String categoryId,
    required bool inStock,
    required List<String> tags,
    required double rating,
    required int reviewCount,
    bool hasDiscount = false,
    double? discountPercentage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        categoryId: categoryId,
        inStock: inStock,
        tags: tags,
        rating: rating,
        reviewCount: reviewCount,
        hasDiscount: hasDiscount,
        discountPercentage: discountPercentage,
      );

      await _database.child('products/$id').update(product.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _database.child('products/$id').remove();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Website Content Management
  Future<String?> initializeDefaultWebsiteConfig() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if website config already exists
      final doc =
          await _firestore.collection('website_config').doc('main').get();

      if (!doc.exists) {
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
              subtitle: 'Discover our curated collection of wellness products',
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
              subtitle: 'Up to 70% off on selected wellness items',
              buttonText: 'Shop Sale',
              buttonAction: '/products?filter=sale',
              gradientColors: ['#FF6B6B', '#FFE66D'],
              badgeText: 'Limited Time Only',
              badgeIcon: '🔥',
              order: 2,
            ),
            BannerItem(
              id: 'banner3',
              title: 'Fast & Free Delivery',
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
              workingHours:
                  'Monday to Saturday: 9 AM - 8 PM\nSunday: 10 AM - 6 PM',
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
Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. We use your information for account management, transaction processing, customer support, marketing communications, and service improvement.

Security of Your Information
We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable.

Contact Us
If you have questions or comments about this Privacy Policy, please contact us at privacy@wellnesshub.com or +91-9876543210.''',
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
                '''Welcome to WellnessHub. These terms and conditions outline the rules and regulations for the use of WellnessHub's Website.

By accessing this website, we assume you accept these terms and conditions. Do not continue to use WellnessHub if you do not agree to take all of the terms and conditions stated on this page.

Use License
Permission is granted to temporarily download one copy of the materials on WellnessHub's website for personal, non-commercial transitory viewing only.

Account Terms
To access some features of the service, you must register for an account. When you create an account, you must provide information that is accurate, complete, and current at all times.

Product Information
We strive to provide accurate product information, including descriptions, images, and pricing. However, we do not warrant that product descriptions or other content is accurate, complete, reliable, current, or error-free.

Pricing and Payment
All prices are listed in Indian Rupees (INR) and are subject to change without notice. Payment is due upon completion of your order.

Shipping and Delivery
We aim to process and ship orders within 1-2 business days. Delivery times may vary based on location and product availability.

Returns and Refunds
We accept returns within 7 days of delivery for most products in original condition. Please refer to our Refund Policy for detailed information.

Contact Information
For questions about these Terms and Conditions, please contact us at legal@wellnesshub.com or +91-9876543210.''',
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
            subtitle:
                'Our commitment to customer satisfaction and fair returns',
            content:
                '''At WellnessHub, your satisfaction is our priority. We strive to provide high-quality products and excellent service. This Refund Policy outlines the terms and conditions for returns, exchanges, and refunds.

Return Eligibility
We accept returns for most products within 7 days of delivery, provided they meet the following conditions:
- Products must be in their original condition and packaging
- Items should be unused and in resalable condition
- Original receipt or proof of purchase is required
- Products must not be expired or near expiry

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

Customer Service
Our customer service team is available to assist with returns and refunds at returns@wellnesshub.com or +91-9876543210, Monday to Saturday, 9 AM - 8 PM.''',
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
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Enhanced sample data with comprehensive website content
  Future<String?> addSampleData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize website configuration first
      await initializeDefaultWebsiteConfig();

      // Add sample categories
      final sampleCategories = [
        {
          'name': 'Vitamins & Supplements',
          'imageUrl':
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
          'description':
              'Essential vitamins and dietary supplements for optimal health and wellness'
        },
        {
          'name': 'Herbal Products',
          'imageUrl':
              'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=500',
          'description':
              'Natural herbal remedies and traditional medicine for holistic health'
        },
        {
          'name': 'Protein & Fitness',
          'imageUrl':
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
          'description':
              'Protein powders and fitness supplements for active lifestyle and muscle building'
        },
        {
          'name': 'Ayurvedic Medicine',
          'imageUrl':
              'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=500',
          'description':
              'Traditional Ayurvedic medicines and treatments for natural healing'
        },
        {
          'name': 'Organic Health Foods',
          'imageUrl':
              'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500',
          'description': 'Organic and natural health foods for nutritious diet'
        },
        {
          'name': 'Personal Care',
          'imageUrl':
              'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=500',
          'description':
              'Natural personal care products for daily wellness routine'
        },
      ];

      Map<String, String> categoryIds = {};
      for (var categoryData in sampleCategories) {
        final docRef =
            await _firestore.collection('categories').add(categoryData);
        categoryIds[categoryData['name']!] = docRef.id;
      }

      // Enhanced sample products with more variety and discounts
      final sampleProducts = [
        // Vitamins & Supplements
        {
          'name': 'Vitamin D3 2000 IU',
          'description':
              'High-potency Vitamin D3 supplement for bone health, immune support, and overall wellness. Each capsule contains 2000 IU of cholecalciferol for optimal absorption.',
          'price': 479.0,
          'originalPrice': 599.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': [
            'vitamin d3',
            'bone health',
            'immunity',
            'cholecalciferol',
            'on sale'
          ],
          'rating': 4.5,
          'reviewCount': 120,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },
        {
          'name': 'Omega 3 Fish Oil 1000mg',
          'description':
              'Premium quality fish oil capsules rich in EPA and DHA for heart health, brain function, and joint support. Sourced from deep-sea fish.',
          'price': 719.0,
          'originalPrice': 899.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1559181567-c3190ca9959b?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': [
            'omega 3',
            'fish oil',
            'heart health',
            'brain health',
            'special offer'
          ],
          'rating': 4.7,
          'reviewCount': 85,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },
        {
          'name': 'Multivitamin Complex',
          'description':
              'Complete daily multivitamin with essential vitamins and minerals for men and women. Supports overall health and energy levels.',
          'price': 999.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1550572017-a4357aeb2ff4?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': [
            'multivitamin',
            'vitamins',
            'minerals',
            'daily health',
            'energy'
          ],
          'rating': 4.3,
          'reviewCount': 156,
          'hasDiscount': false,
        },
        {
          'name': 'Vitamin C 1000mg',
          'description':
              'High-potency Vitamin C tablets for immune system support and antioxidant protection. Enhanced with rose hips for better absorption.',
          'price': 319.0,
          'originalPrice': 399.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': [
            'vitamin c',
            'immunity',
            'antioxidant',
            'rose hips',
            'flash sale'
          ],
          'rating': 4.4,
          'reviewCount': 98,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },

        // Herbal Products
        {
          'name': 'Ashwagandha Extract 500mg',
          'description':
              'Pure Ashwagandha root extract for stress relief, energy boost, and mental clarity. Standardized to 5% withanolides for maximum potency.',
          'price': 599.0,
          'originalPrice': 749.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=500',
          'categoryId': categoryIds['Herbal Products']!,
          'inStock': true,
          'tags': [
            'ashwagandha',
            'stress relief',
            'adaptogen',
            'ayurveda',
            'mega sale'
          ],
          'rating': 4.6,
          'reviewCount': 95,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },
        {
          'name': 'Turmeric Curcumin 500mg',
          'description':
              'Organic turmeric with curcumin and black pepper extract for enhanced absorption. Anti-inflammatory and antioxidant properties.',
          'price': 519.0,
          'originalPrice': 649.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=500',
          'categoryId': categoryIds['Herbal Products']!,
          'inStock': true,
          'tags': [
            'turmeric',
            'curcumin',
            'anti-inflammatory',
            'antioxidant',
            'flash sale'
          ],
          'rating': 4.4,
          'reviewCount': 78,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },
        {
          'name': 'Ginkgo Biloba Extract',
          'description':
              'Standardized Ginkgo Biloba extract for cognitive support and improved blood circulation. Supports memory and mental focus.',
          'price': 799.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=500',
          'categoryId': categoryIds['Herbal Products']!,
          'inStock': true,
          'tags': [
            'ginkgo biloba',
            'cognitive support',
            'memory',
            'circulation'
          ],
          'rating': 4.2,
          'reviewCount': 67,
          'hasDiscount': false,
        },

        // Add more products for other categories...
        // (I'll include a few more key products to keep the response manageable)

        // Protein & Fitness
        {
          'name': 'Whey Protein Isolate',
          'description':
              'Fast-absorbing whey protein isolate with 25g protein per serving. Perfect for post-workout recovery and muscle building.',
          'price': 1999.0,
          'originalPrice': 2499.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
          'categoryId': categoryIds['Protein & Fitness']!,
          'inStock': true,
          'tags': [
            'whey protein',
            'isolate',
            'muscle building',
            'post workout',
            'limited time'
          ],
          'rating': 4.8,
          'reviewCount': 210,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },

        // Ayurvedic Medicine
        {
          'name': 'Chyawanprash 500g',
          'description':
              'Traditional Ayurvedic immunity booster with 40+ herbs and natural ingredients. Supports respiratory health and vitality.',
          'price': 360.0,
          'originalPrice': 450.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1605833439443-ee51d1eb2567?w=500',
          'categoryId': categoryIds['Ayurvedic Medicine']!,
          'inStock': true,
          'tags': [
            'chyawanprash',
            'immunity',
            'ayurveda',
            'herbs',
            'festival offer'
          ],
          'rating': 4.7,
          'reviewCount': 203,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },

        // Organic Health Foods
        {
          'name': 'Organic Chia Seeds 500g',
          'description':
              'Premium organic chia seeds rich in omega-3, fiber, and protein. Perfect for smoothies, yogurt, and healthy recipes.',
          'price': 399.0,
          'originalPrice': 499.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500',
          'categoryId': categoryIds['Organic Health Foods']!,
          'inStock': true,
          'tags': [
            'chia seeds',
            'organic',
            'omega 3',
            'fiber',
            'superfood',
            'sale'
          ],
          'rating': 4.5,
          'reviewCount': 76,
          'hasDiscount': true,
          'discountPercentage': 20.0,
        },

        // Personal Care
        {
          'name': 'Neem Face Wash 100ml',
          'description':
              'Natural neem face wash for acne-prone skin. Gentle cleansing with antibacterial properties. Suitable for daily use.',
          'price': 179.0,
          'originalPrice': 229.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=500',
          'categoryId': categoryIds['Personal Care']!,
          'inStock': true,
          'tags': [
            'neem',
            'face wash',
            'acne',
            'antibacterial',
            'natural',
            'offer'
          ],
          'rating': 4.2,
          'reviewCount': 89,
          'hasDiscount': true,
          'discountPercentage': 22.0,
        },
      ];

      for (var productData in sampleProducts) {
        await _database.child('products').push().set(productData);
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Order Management
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  Future<String?> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Analytics Methods
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      // Get total products
      final productsSnapshot = await _database.child('products').once();
      final totalProducts = productsSnapshot.snapshot.children.length;

      // Get total categories
      final categoriesSnapshot =
          await _firestore.collection('categories').get();
      final totalCategories = categoriesSnapshot.docs.length;

      // Get total orders
      final ordersSnapshot = await _firestore.collection('orders').get();
      final totalOrders = ordersSnapshot.docs.length;

      // Calculate total revenue (sum of all completed orders)
      double totalRevenue = 0.0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed' || data['status'] == 'delivered') {
          totalRevenue += (data['total'] ?? 0.0).toDouble();
        }
      }

      return {
        'totalProducts': totalProducts,
        'totalCategories': totalCategories,
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {
        'totalProducts': 0,
        'totalCategories': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
