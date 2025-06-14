// providers/admin_provider.dart - Enhanced with quantity and multi-category support
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

  // Categories Management (unchanged)
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

  // Enhanced Products Management with quantity and multi-category support
  Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    required String imageUrl,
    required String categoryId, // Primary category
    List<String>? additionalCategoryIds, // Additional categories
    required bool inStock,
    required List<String> tags,
    required double rating,
    required int reviewCount,
    bool hasDiscount = false,
    double? discountPercentage,
    // New quantity and unit parameters
    double? quantity,
    String? unit,
    String? quantityDisplay,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate quantity and unit
      String? validationError = _validateQuantityUnit(quantity, unit);
      if (validationError != null) {
        _isLoading = false;
        notifyListeners();
        return validationError;
      }

      // Generate quantity display if not provided
      String? finalQuantityDisplay = quantityDisplay;
      if (finalQuantityDisplay == null || finalQuantityDisplay.isEmpty) {
        if (quantity != null && unit != null && unit.isNotEmpty) {
          finalQuantityDisplay =
              ProductUnitHelper.formatQuantityUnit(quantity, unit);
        }
      }

      final product = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        categoryId: categoryId,
        categoryIds: additionalCategoryIds ?? [],
        inStock: inStock,
        tags: tags,
        rating: rating,
        reviewCount: reviewCount,
        hasDiscount: hasDiscount,
        discountPercentage: discountPercentage,
        quantity: quantity,
        unit: unit,
        quantityDisplay: finalQuantityDisplay,
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
    required String categoryId, // Primary category
    List<String>? additionalCategoryIds, // Additional categories
    required bool inStock,
    required List<String> tags,
    required double rating,
    required int reviewCount,
    bool hasDiscount = false,
    double? discountPercentage,
    // New quantity and unit parameters
    double? quantity,
    String? unit,
    String? quantityDisplay,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate quantity and unit
      String? validationError = _validateQuantityUnit(quantity, unit);
      if (validationError != null) {
        _isLoading = false;
        notifyListeners();
        return validationError;
      }

      // Generate quantity display if not provided
      String? finalQuantityDisplay = quantityDisplay;
      if (finalQuantityDisplay == null || finalQuantityDisplay.isEmpty) {
        if (quantity != null && unit != null && unit.isNotEmpty) {
          finalQuantityDisplay =
              ProductUnitHelper.formatQuantityUnit(quantity, unit);
        }
      }

      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        categoryId: categoryId,
        categoryIds: additionalCategoryIds ?? [],
        inStock: inStock,
        tags: tags,
        rating: rating,
        reviewCount: reviewCount,
        hasDiscount: hasDiscount,
        discountPercentage: discountPercentage,
        quantity: quantity,
        unit: unit,
        quantityDisplay: finalQuantityDisplay,
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

  // Validate quantity and unit inputs
  String? _validateQuantityUnit(double? quantity, String? unit) {
    if (quantity != null && quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (quantity != null && (unit == null || unit.isEmpty)) {
      return 'Unit is required when quantity is specified';
    }

    if (unit != null && unit.isNotEmpty && quantity == null) {
      return 'Quantity is required when unit is specified';
    }

    return null;
  }

  // Get all categories for multi-select
  Future<List<Category>> getAllCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Get products by multiple categories
  Future<List<Product>> getProductsByCategories(
      List<String> categoryIds) async {
    try {
      final snapshot = await _database.child('products').once();
      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        return data.entries
            .map((entry) => Product.fromMap(
                Map<String, dynamic>.from(entry.value), entry.key))
            .where((product) => categoryIds
                .any((categoryId) => product.belongsToCategory(categoryId)))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products by categories: $e');
      return [];
    }
  }

  // Enhanced sample data with quantity information
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

      // Enhanced sample products with quantity and multi-category support
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
          'categoryIds': [
            categoryIds['Personal Care']!
          ], // Also in Personal Care
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
          'quantity': 60.0,
          'unit': 'capsules',
          'quantityDisplay': '60 capsules',
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
          'categoryIds': [], // Single category
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
          'quantity': 90.0,
          'unit': 'capsules',
          'quantityDisplay': '90 capsules',
        },
        {
          'name': 'Multivitamin Complex',
          'description':
              'Complete daily multivitamin with essential vitamins and minerals for men and women. Supports overall health and energy levels.',
          'price': 999.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1550572017-a4357aeb2ff4?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'categoryIds': [],
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
          'quantity': 30.0,
          'unit': 'tablets',
          'quantityDisplay': '30 tablets',
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
          'categoryIds': [],
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
          'quantity': 120.0,
          'unit': 'tablets',
          'quantityDisplay': '120 tablets',
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
          'categoryIds': [categoryIds['Ayurvedic Medicine']!], // Also Ayurvedic
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
          'quantity': 60.0,
          'unit': 'capsules',
          'quantityDisplay': '60 capsules',
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
          'categoryIds': [categoryIds['Ayurvedic Medicine']!],
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
          'quantity': 90.0,
          'unit': 'capsules',
          'quantityDisplay': '90 capsules',
        },

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
          'categoryIds': [],
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
          'quantity': 1.0,
          'unit': 'kg',
          'quantityDisplay': '1 kg',
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
          'categoryIds': [categoryIds['Herbal Products']!], // Also Herbal
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
          'quantity': 500.0,
          'unit': 'gm',
          'quantityDisplay': '500 gm',
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
          'categoryIds': [],
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
          'quantity': 500.0,
          'unit': 'gm',
          'quantityDisplay': '500 gm',
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
          'categoryIds': [categoryIds['Herbal Products']!], // Also Herbal
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
          'quantity': 100.0,
          'unit': 'ml',
          'quantityDisplay': '100 ml',
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

  // Bulk update products to add quantity information
  Future<String?> bulkUpdateProductsWithQuantity() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _database.child('products').once();
      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        for (var entry in data.entries) {
          final productId = entry.key;
          final productData = Map<String, dynamic>.from(entry.value);

          // Skip if quantity already exists
          if (productData['quantity'] != null) continue;

          // Add default quantity based on product type
          String productName =
              productData['name']?.toString().toLowerCase() ?? '';
          Map<String, dynamic> updates = {};

          if (productName.contains('capsule') ||
              productName.contains('tablet')) {
            updates['quantity'] = 60.0;
            updates['unit'] =
                productName.contains('capsule') ? 'capsules' : 'tablets';
          } else if (productName.contains('powder') ||
              productName.contains('protein')) {
            updates['quantity'] = 1.0;
            updates['unit'] = 'kg';
          } else if (productName.contains('oil') ||
              productName.contains('wash')) {
            updates['quantity'] = 100.0;
            updates['unit'] = 'ml';
          } else if (productName.contains('seeds') ||
              productName.contains('chyawanprash')) {
            updates['quantity'] = 500.0;
            updates['unit'] = 'gm';
          } else {
            // Default for other products
            updates['quantity'] = 1.0;
            updates['unit'] = 'piece';
          }

          if (updates['quantity'] != null && updates['unit'] != null) {
            updates['quantityDisplay'] = ProductUnitHelper.formatQuantityUnit(
                updates['quantity'], updates['unit']);
          }

          await _database.child('products/$productId').update(updates);
        }
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

  // Add products to additional categories
  Future<String?> addProductToCategories(
      String productId, List<String> newCategoryIds) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _database.child('products/$productId').once();
      if (snapshot.snapshot.exists) {
        final productData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        // Get existing category IDs
        List<String> existingCategoryIds = [];
        if (productData['categoryIds'] != null) {
          existingCategoryIds = List<String>.from(productData['categoryIds']);
        }

        // Add new categories (avoid duplicates)
        Set<String> allCategoryIds = Set.from(existingCategoryIds);
        allCategoryIds.addAll(newCategoryIds);

        await _database.child('products/$productId').update({
          'categoryIds': allCategoryIds.toList(),
        });
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

  // Remove products from categories
  Future<String?> removeProductFromCategories(
      String productId, List<String> categoryIdsToRemove) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _database.child('products/$productId').once();
      if (snapshot.snapshot.exists) {
        final productData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        // Get existing category IDs
        List<String> existingCategoryIds = [];
        if (productData['categoryIds'] != null) {
          existingCategoryIds = List<String>.from(productData['categoryIds']);
        }

        // Remove specified categories
        existingCategoryIds
            .removeWhere((id) => categoryIdsToRemove.contains(id));

        await _database.child('products/$productId').update({
          'categoryIds': existingCategoryIds,
        });
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

  // Get unit suggestions for admin UI
  List<String> getUnitSuggestions() {
    return ProductUnitHelper.commonUnits;
  }

  // Get unit suggestions by type
  List<String> getUnitSuggestionsByType(ProductUnitType type) {
    return ProductUnitHelper.getUnitSuggestions(type);
  }

  // Website Content Management (unchanged methods)
  Future<String?> initializeDefaultWebsiteConfig() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if website config already exists
      final doc =
          await _firestore.collection('website_config').doc('main').get();

      if (!doc.exists) {
        final defaultConfig = WebsiteConfig(
          contactUs: PageContent(
              title: 'title',
              subtitle: 'subtitle',
              content: 'content',
              keyPoints: [],
              lastUpdated: DateTime.now()),
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
            content: 'Welcome to WellnessHub...',
            keyPoints: ['Premium quality products'],
            contactInfo: ContactInfo(
              email: 'info@wellnesshub.com',
              phone: '+91-9876543210',
              address: '123 Wellness Street',
              workingHours: 'Monday to Saturday: 9 AM - 8 PM',
            ),
            lastUpdated: DateTime.now(),
          ),
          privacyPolicy: PageContent(
            title: 'Privacy Policy',
            subtitle: 'How we protect your information',
            content: 'At WellnessHub, we are committed...',
            keyPoints: ['Data protection'],
            lastUpdated: DateTime.now(),
          ),
          termsConditions: PageContent(
            title: 'Terms and Conditions',
            subtitle: 'Terms of service',
            content: 'Welcome to WellnessHub...',
            keyPoints: ['Fair terms'],
            lastUpdated: DateTime.now(),
          ),
          refundPolicy: PageContent(
            title: 'Refund Policy',
            subtitle: 'Our commitment to customer satisfaction',
            content: 'At WellnessHub, your satisfaction...',
            keyPoints: ['7-day return window'],
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

  // Order Management (unchanged)
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

  // Analytics Methods (unchanged)
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
