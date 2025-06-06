// admin/admin_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';
import '../models/category.dart';

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
    required String imageUrl,
    required String categoryId,
    required bool inStock,
    required List<String> tags,
    required double rating,
    required int reviewCount,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final product = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        categoryId: categoryId,
        inStock: inStock,
        tags: tags,
        rating: rating,
        reviewCount: reviewCount,
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
    required String imageUrl,
    required String categoryId,
    required bool inStock,
    required List<String> tags,
    required double rating,
    required int reviewCount,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        categoryId: categoryId,
        inStock: inStock,
        tags: tags,
        rating: rating,
        reviewCount: reviewCount,
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

  // Bulk Operations
  Future<String?> addSampleData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Add sample categories
      final sampleCategories = [
        {
          'name': 'Vitamins & Supplements',
          'imageUrl':
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
          'description':
              'Essential vitamins and dietary supplements for optimal health'
        },
        {
          'name': 'Herbal Products',
          'imageUrl':
              'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=500',
          'description': 'Natural herbal remedies and traditional medicine'
        },
        {
          'name': 'Protein & Fitness',
          'imageUrl':
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
          'description':
              'Protein powders and fitness supplements for active lifestyle'
        },
        {
          'name': 'Ayurvedic Medicine',
          'imageUrl':
              'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=500',
          'description': 'Traditional Ayurvedic medicines and treatments'
        },
      ];

      Map<String, String> categoryIds = {};

      for (var categoryData in sampleCategories) {
        final docRef =
            await _firestore.collection('categories').add(categoryData);
        categoryIds[categoryData['name']!] = docRef.id;
      }

      // Add sample products
      final sampleProducts = [
        {
          'name': 'Vitamin D3 2000 IU',
          'description':
              'High-potency Vitamin D3 supplement for bone health, immune support, and overall wellness. Each capsule contains 2000 IU of cholecalciferol.',
          'price': 599.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': ['vitamin d3', 'bone health', 'immunity', 'cholecalciferol'],
          'rating': 4.5,
          'reviewCount': 120
        },
        {
          'name': 'Omega 3 Fish Oil 1000mg',
          'description':
              'Premium quality fish oil capsules rich in EPA and DHA for heart health, brain function, and joint support.',
          'price': 899.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1559181567-c3190ca9959b?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': ['omega 3', 'fish oil', 'heart health', 'brain health'],
          'rating': 4.7,
          'reviewCount': 85
        },
        {
          'name': 'Ashwagandha Extract 500mg',
          'description':
              'Pure Ashwagandha root extract for stress relief, energy boost, and mental clarity. Standardized to 5% withanolides.',
          'price': 749.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=500',
          'categoryId': categoryIds['Herbal Products']!,
          'inStock': true,
          'tags': ['ashwagandha', 'stress relief', 'adaptogen', 'ayurveda'],
          'rating': 4.6,
          'reviewCount': 95
        },
        {
          'name': 'Whey Protein Isolate',
          'description':
              'Fast-absorbing whey protein isolate with 25g protein per serving. Perfect for post-workout recovery and muscle building.',
          'price': 2499.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
          'categoryId': categoryIds['Protein & Fitness']!,
          'inStock': true,
          'tags': [
            'whey protein',
            'isolate',
            'muscle building',
            'post workout'
          ],
          'rating': 4.8,
          'reviewCount': 210
        },
        {
          'name': 'Turmeric Curcumin 500mg',
          'description':
              'Organic turmeric with curcumin and black pepper extract for enhanced absorption. Anti-inflammatory and antioxidant properties.',
          'price': 649.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=500',
          'categoryId': categoryIds['Herbal Products']!,
          'inStock': true,
          'tags': ['turmeric', 'curcumin', 'anti-inflammatory', 'antioxidant'],
          'rating': 4.4,
          'reviewCount': 78
        },
        {
          'name': 'Multivitamin Complex',
          'description':
              'Complete daily multivitamin with essential vitamins and minerals for men and women. Supports overall health and energy.',
          'price': 999.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1550572017-a4357aeb2ff4?w=500',
          'categoryId': categoryIds['Vitamins & Supplements']!,
          'inStock': true,
          'tags': ['multivitamin', 'vitamins', 'minerals', 'daily health'],
          'rating': 4.3,
          'reviewCount': 156
        },
        {
          'name': 'Chyawanprash 500g',
          'description':
              'Traditional Ayurvedic immunity booster with 40+ herbs and natural ingredients. Supports respiratory health and vitality.',
          'price': 450.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1605833439443-ee51d1eb2567?w=500',
          'categoryId': categoryIds['Ayurvedic Medicine']!,
          'inStock': true,
          'tags': ['chyawanprash', 'immunity', 'ayurveda', 'herbs'],
          'rating': 4.7,
          'reviewCount': 203
        },
        {
          'name': 'BCAA Energy Powder',
          'description':
              'Branched-chain amino acids with natural caffeine for energy and muscle recovery. Perfect for pre and post-workout.',
          'price': 1799.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1594737626072-90dc274bc2bd?w=500',
          'categoryId': categoryIds['Protein & Fitness']!,
          'inStock': true,
          'tags': ['bcaa', 'amino acids', 'energy', 'pre workout'],
          'rating': 4.5,
          'reviewCount': 92
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
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
