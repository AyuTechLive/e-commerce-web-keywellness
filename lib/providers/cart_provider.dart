// providers/cart_provider.dart - Enhanced with quantity and unit support
import 'package:flutter/material.dart';
import 'package:keiwaywellness/models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;
  int get itemCount => _items.length;

  // Calculate total amount (discounted prices)
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  // Calculate original total (before discounts)
  double get originalTotalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.originalTotal);
  }

  // Calculate total savings
  double get totalSavings {
    return _items.fold(0.0, (sum, item) => sum + item.savings);
  }

  // Check if cart has any discounts
  bool get hasDiscounts {
    return _items.any((item) => item.hasDiscount);
  }

  // Get discount percentage for the entire cart
  double get cartDiscountPercentage {
    if (originalTotalAmount > 0) {
      return (totalSavings / originalTotalAmount) * 100;
    }
    return 0.0;
  }

  // Get items with discounts
  List<CartItemModel> get discountedItems {
    return _items.where((item) => item.hasDiscount).toList();
  }

  // Get total number of packages/units in cart
  int get totalPackages {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get cart summary with quantity information
  Map<String, dynamic> get cartSummary {
    Map<String, int> unitTypeCounts = {};
    double totalWeight = 0.0;
    double totalVolume = 0.0;
    int totalMedicineCount = 0;

    for (var item in _items) {
      if (item.productUnit != null && item.totalProductQuantity != null) {
        final unit = item.productUnit!.toLowerCase();
        final totalQty = item.totalProductQuantity!;

        if (['gm', 'g', 'kg'].contains(unit)) {
          double weightInGrams = unit == 'kg' ? totalQty * 1000 : totalQty;
          totalWeight += weightInGrams;
          unitTypeCounts['weight'] = (unitTypeCounts['weight'] ?? 0) + 1;
        } else if (['ml', 'l'].contains(unit)) {
          double volumeInMl = unit == 'l' ? totalQty * 1000 : totalQty;
          totalVolume += volumeInMl;
          unitTypeCounts['liquid'] = (unitTypeCounts['liquid'] ?? 0) + 1;
        } else if (['capsule', 'tablet', 'cap', 'tab'].contains(unit)) {
          totalMedicineCount += totalQty.toInt();
          unitTypeCounts['medicine'] = (unitTypeCounts['medicine'] ?? 0) + 1;
        } else {
          unitTypeCounts['other'] = (unitTypeCounts['other'] ?? 0) + 1;
        }
      }
    }

    return {
      'totalPackages': totalPackages,
      'totalWeight': totalWeight,
      'totalVolume': totalVolume,
      'totalMedicineCount': totalMedicineCount,
      'unitTypeCounts': unitTypeCounts,
      'estimatedDeliveryWeight': _calculateDeliveryWeight(),
    };
  }

  double _calculateDeliveryWeight() {
    // Estimate package weight for delivery calculation
    double weight = 0.0;
    for (var item in _items) {
      // Base weight per package (packaging + product)
      double packageWeight = 0.1; // 100g base packaging

      if (item.productUnit != null && item.productQuantity != null) {
        final unit = item.productUnit!.toLowerCase();
        if (['gm', 'g'].contains(unit)) {
          packageWeight += item.productQuantity! / 1000; // Convert to kg
        } else if (unit == 'kg') {
          packageWeight += item.productQuantity!;
        } else if (['ml', 'l'].contains(unit)) {
          double volumeInLiters = unit == 'l'
              ? item.productQuantity!
              : item.productQuantity! / 1000;
          packageWeight += volumeInLiters * 1.0; // Assume density of 1kg/L
        } else {
          packageWeight += 0.05; // Default 50g for pills/capsules
        }
      } else {
        packageWeight = 0.3; // Default 300g per package
      }

      weight += packageWeight * item.quantity;
    }

    return weight;
  }

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cart');
    if (cartData != null) {
      final List<dynamic> cartList = json.decode(cartData);
      _items = cartList.map((item) => CartItemModel.fromMap(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(_items.map((item) => item.toMap()).toList());
    await prefs.setString('cart', cartData);
  }

  // Enhanced addItem method with quantity and unit support
  void addItem(
    String productId,
    String name,
    double price,
    String imageUrl, {
    double? originalPrice,
    double? productQuantity,
    String? productUnit,
    String? quantityDisplay,
  }) {
    final existingIndex =
        _items.indexWhere((item) => item.productId == productId);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItemModel(
        productId: productId,
        name: name,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        productQuantity: productQuantity,
        productUnit: productUnit,
        quantityDisplay: quantityDisplay,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  // Enhanced addItemFromProduct method for Product objects
  void addItemFromProduct(dynamic product) {
    addItem(
      product.id,
      product.name,
      product.price,
      product.imageUrl,
      originalPrice: product.originalPrice,
      productQuantity: product.quantity,
      productUnit: product.unit,
      quantityDisplay: product.quantityDisplay,
    );
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItemModel(
          productId: '', name: '', price: 0, imageUrl: '', quantity: 0),
    );
    return item.quantity;
  }

  // Get item details by product ID
  CartItemModel? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Get discount summary for checkout with enhanced information
  Map<String, dynamic> getDiscountSummary() {
    final discountDetails = <DiscountDetail>[];

    for (final item in _items) {
      if (item.hasDiscount) {
        discountDetails.add(DiscountDetail(
          productName: item.name,
          originalPrice: item.originalPrice!,
          discountedPrice: item.price,
          quantity: item.quantity,
          savingsAmount: item.savings,
          discountPercentage: item.discountPercentage,
        ));
      }
    }

    return {
      'originalTotal': originalTotalAmount,
      'discountedTotal': totalAmount,
      'totalSavings': totalSavings,
      'discountPercentage': cartDiscountPercentage,
      'hasDiscounts': hasDiscounts,
      'discountDetails': discountDetails,
      'discountedItemsCount': discountedItems.length,
      'cartSummary': cartSummary,
    };
  }

  // Get items grouped by unit type
  Map<String, List<CartItemModel>> getItemsByUnitType() {
    Map<String, List<CartItemModel>> grouped = {
      'medicine': [],
      'liquid': [],
      'weight': [],
      'other': [],
    };

    for (var item in _items) {
      if (item.productUnit != null) {
        final unit = item.productUnit!.toLowerCase();
        if (['capsule', 'tablet', 'cap', 'tab'].contains(unit)) {
          grouped['medicine']!.add(item);
        } else if (['ml', 'l'].contains(unit)) {
          grouped['liquid']!.add(item);
        } else if (['gm', 'g', 'kg'].contains(unit)) {
          grouped['weight']!.add(item);
        } else {
          grouped['other']!.add(item);
        }
      } else {
        grouped['other']!.add(item);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  // Get shipping estimate based on cart weight and dimensions
  Map<String, dynamic> getShippingEstimate() {
    final summary = cartSummary;
    final weight = summary['estimatedDeliveryWeight'] as double;

    // Simple shipping calculation based on weight
    double shippingCost = 0.0;
    String estimatedDays = '3-5';

    if (totalAmount >= 500) {
      shippingCost = 0.0; // Free shipping
      estimatedDays = '2-4';
    } else if (weight <= 0.5) {
      shippingCost = 40.0;
      estimatedDays = '3-5';
    } else if (weight <= 2.0) {
      shippingCost = 60.0;
      estimatedDays = '3-5';
    } else {
      shippingCost = 80.0;
      estimatedDays = '4-6';
    }

    return {
      'cost': shippingCost,
      'estimatedDays': estimatedDays,
      'weight': weight,
      'freeShippingEligible': totalAmount >= 500,
      'amountForFreeShipping': totalAmount >= 500 ? 0.0 : (500 - totalAmount),
    };
  }

  // Validate cart items (check for out of stock, price changes, etc.)
  Future<List<String>> validateCart() async {
    List<String> issues = [];

    // Check for empty cart
    if (_items.isEmpty) {
      issues.add('Your cart is empty');
      return issues;
    }

    // Check for zero quantity items
    final zeroQuantityItems =
        _items.where((item) => item.quantity <= 0).toList();
    if (zeroQuantityItems.isNotEmpty) {
      for (var item in zeroQuantityItems) {
        issues.add('${item.name} has invalid quantity');
      }
    }

    // Check for items with missing information
    final invalidItems = _items
        .where((item) =>
            item.name.isEmpty || item.price <= 0 || item.imageUrl.isEmpty)
        .toList();

    if (invalidItems.isNotEmpty) {
      for (var item in invalidItems) {
        issues.add(
            '${item.name.isEmpty ? 'Unknown product' : item.name} has invalid information');
      }
    }

    return issues;
  }

  // Get recommended products based on cart items
  Future<List<dynamic>> getRecommendedProducts() async {
    // This would typically call the ProductProvider
    // For now, return empty list
    return [];
  }

  // Calculate savings breakdown
  Map<String, dynamic> getSavingsBreakdown() {
    Map<String, double> savingsByCategory = {};
    double totalItemSavings = 0.0;

    for (var item in _items) {
      if (item.hasDiscount) {
        totalItemSavings += item.savings;
        // Group by product type if needed
        String category = 'Products';
        if (item.productUnit != null) {
          final unit = item.productUnit!.toLowerCase();
          if (['capsule', 'tablet'].contains(unit)) {
            category = 'Medicines';
          } else if (['ml', 'l'].contains(unit)) {
            category = 'Liquids';
          } else if (['gm', 'g', 'kg'].contains(unit)) {
            category = 'Health Foods';
          }
        }
        savingsByCategory[category] =
            (savingsByCategory[category] ?? 0.0) + item.savings;
      }
    }

    return {
      'totalSavings': totalItemSavings,
      'savingsByCategory': savingsByCategory,
      'savingsPercentage': cartDiscountPercentage,
      'itemsWithSavings': discountedItems.length,
    };
  }
}
