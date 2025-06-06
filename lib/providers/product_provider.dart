import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;

  ProductProvider() {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _database.child('products').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _products = data.entries
            .map((entry) => Product.fromMap(
                Map<String, dynamic>.from(entry.value), entry.key))
            .toList();

        _featuredProducts =
            _products.where((p) => p.rating >= 4.0).take(6).toList();
      }
    } catch (e) {
      print('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> getProduct(String id) async {
    try {
      final snapshot = await _database.child('products/$id').get();
      if (snapshot.exists) {
        return Product.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map), id);
      }
    } catch (e) {
      print('Error getting product: $e');
    }
    return null;
  }

  List<Product> getProductsByCategory(String categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(lowercaseQuery) ||
            product.description.toLowerCase().contains(lowercaseQuery) ||
            product.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseQuery)))
        .toList();
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }
}
