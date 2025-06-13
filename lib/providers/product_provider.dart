// providers/product_provider.dart - Enhanced with multi-category support
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

  // Enhanced: Get products by category (supports multi-category)
  List<Product> getProductsByCategory(String categoryId) {
    return _products
        .where((product) => product.belongsToCategory(categoryId))
        .toList();
  }

  // New: Get products by multiple categories
  List<Product> getProductsByCategories(List<String> categoryIds) {
    return _products
        .where((product) => categoryIds
            .any((categoryId) => product.belongsToCategory(categoryId)))
        .toList();
  }

  // Enhanced: Search products with quantity information
  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(lowercaseQuery) ||
            product.description.toLowerCase().contains(lowercaseQuery) ||
            product.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
            (product.formattedQuantity
                .toLowerCase()
                .contains(lowercaseQuery)) ||
            (product.unit?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }

  // New: Filter products by unit type
  List<Product> getProductsByUnitType(ProductUnitType unitType) {
    return _products.where((product) => product.unitType == unitType).toList();
  }

  // New: Get products with discounts
  List<Product> getDiscountedProducts() {
    return _products.where((product) => product.isOnSale).toList();
  }

  // New: Get products by price range
  List<Product> getProductsByPriceRange(double minPrice, double maxPrice) {
    return _products
        .where(
            (product) => product.price >= minPrice && product.price <= maxPrice)
        .toList();
  }

  // New: Get products by rating
  List<Product> getProductsByRating(double minRating) {
    return _products.where((product) => product.rating >= minRating).toList();
  }

  // New: Sort products
  List<Product> sortProducts(
      List<Product> products, ProductSortOption sortOption) {
    List<Product> sortedProducts = List.from(products);

    switch (sortOption) {
      case ProductSortOption.nameAsc:
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        sortedProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.priceAsc:
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.ratingDesc:
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.discountDesc:
        sortedProducts.sort((a, b) => b.calculatedDiscountPercentage
            .compareTo(a.calculatedDiscountPercentage));
        break;
      case ProductSortOption.newest:
        // Assuming products are loaded in order, keep current order
        break;
    }

    return sortedProducts;
  }

  // New: Advanced search with filters
  List<Product> advancedSearch({
    String? query,
    List<String>? categoryIds,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStock,
    bool? onSale,
    ProductUnitType? unitType,
    ProductSortOption? sortOption,
  }) {
    List<Product> filtered = List.from(_products);

    // Apply filters
    if (query != null && query.isNotEmpty) {
      filtered = searchProducts(query);
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      filtered = filtered
          .where((product) => categoryIds
              .any((categoryId) => product.belongsToCategory(categoryId)))
          .toList();
    }

    if (minPrice != null) {
      filtered =
          filtered.where((product) => product.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      filtered =
          filtered.where((product) => product.price <= maxPrice).toList();
    }

    if (minRating != null) {
      filtered =
          filtered.where((product) => product.rating >= minRating).toList();
    }

    if (inStock != null) {
      filtered =
          filtered.where((product) => product.inStock == inStock).toList();
    }

    if (onSale != null && onSale) {
      filtered = filtered.where((product) => product.isOnSale).toList();
    }

    if (unitType != null) {
      filtered =
          filtered.where((product) => product.unitType == unitType).toList();
    }

    // Apply sorting
    if (sortOption != null) {
      filtered = sortProducts(filtered, sortOption);
    }

    return filtered;
  }

  // New: Get product statistics
  Map<String, dynamic> getProductStatistics() {
    if (_products.isEmpty) {
      return {
        'totalProducts': 0,
        'averagePrice': 0.0,
        'averageRating': 0.0,
        'inStockCount': 0,
        'onSaleCount': 0,
        'unitTypes': <String, int>{},
      };
    }

    double totalPrice =
        _products.fold(0.0, (sum, product) => sum + product.price);
    double totalRating =
        _products.fold(0.0, (sum, product) => sum + product.rating);
    int inStockCount = _products.where((product) => product.inStock).length;
    int onSaleCount = _products.where((product) => product.isOnSale).length;

    // Count products by unit type
    Map<String, int> unitTypeCounts = {};
    for (var product in _products) {
      String unitType = product.unitType.toString().split('.').last;
      unitTypeCounts[unitType] = (unitTypeCounts[unitType] ?? 0) + 1;
    }

    return {
      'totalProducts': _products.length,
      'averagePrice': totalPrice / _products.length,
      'averageRating': totalRating / _products.length,
      'inStockCount': inStockCount,
      'onSaleCount': onSaleCount,
      'unitTypes': unitTypeCounts,
    };
  }

  // New: Get popular tags
  List<String> getPopularTags({int limit = 20}) {
    Map<String, int> tagCounts = {};

    for (var product in _products) {
      for (var tag in product.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    var sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(limit).map((entry) => entry.key).toList();
  }

  // New: Get recommended products based on a product
  List<Product> getRecommendedProducts(Product product, {int limit = 4}) {
    List<Product> recommended = [];

    // First, get products from same categories
    var sameCategoryProducts = _products
        .where((p) =>
            p.id != product.id &&
            product.allCategoryIds
                .any((categoryId) => p.belongsToCategory(categoryId)))
        .toList();

    recommended.addAll(sameCategoryProducts.take(limit));

    // If we need more, get products with similar tags
    if (recommended.length < limit) {
      var similarTagProducts = _products
          .where((p) =>
              p.id != product.id &&
              !recommended.any((r) => r.id == p.id) &&
              product.tags.any((tag) => p.tags.contains(tag)))
          .toList();

      recommended.addAll(similarTagProducts.take(limit - recommended.length));
    }

    // If still need more, get highly rated products
    if (recommended.length < limit) {
      var highRatedProducts = _products
          .where((p) =>
              p.id != product.id &&
              !recommended.any((r) => r.id == p.id) &&
              p.rating >= 4.0)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      recommended.addAll(highRatedProducts.take(limit - recommended.length));
    }

    return recommended.take(limit).toList();
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }
}

// Enum for sorting options
enum ProductSortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  ratingDesc,
  discountDesc,
  newest,
}

// Extension for sorting option labels
extension ProductSortOptionExtension on ProductSortOption {
  String get label {
    switch (this) {
      case ProductSortOption.nameAsc:
        return 'Name: A to Z';
      case ProductSortOption.nameDesc:
        return 'Name: Z to A';
      case ProductSortOption.priceAsc:
        return 'Price: Low to High';
      case ProductSortOption.priceDesc:
        return 'Price: High to Low';
      case ProductSortOption.ratingDesc:
        return 'Highest Rated';
      case ProductSortOption.discountDesc:
        return 'Highest Discount';
      case ProductSortOption.newest:
        return 'Newest First';
    }
  }
}
