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

  void addItem(String productId, String name, double price, String imageUrl,
      {double? originalPrice}) {
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
      ));
    }

    _saveCart();
    notifyListeners();
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

  // Get discount summary for checkout
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
    };
  }
}
