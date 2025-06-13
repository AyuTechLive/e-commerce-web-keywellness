// models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced CartItemModel with quantity and unit support
class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final double? originalPrice; // Add original price for discount tracking
  final String imageUrl;
  int quantity;

  // New quantity and unit fields
  final double?
      productQuantity; // Product package quantity (e.g., 500 for 500ml)
  final String? productUnit; // Product unit (e.g., "ml", "gm", "capsules")
  final String? quantityDisplay; // Combined display like "500ml", "30 capsules"

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.quantity = 1,
    this.productQuantity,
    this.productUnit,
    this.quantityDisplay,
  });

  double get total => price * quantity;

  // Calculate original total (before discount)
  double get originalTotal {
    if (originalPrice != null) {
      return originalPrice! * quantity;
    }
    return total;
  }

  // Calculate savings for this item
  double get savings {
    if (originalPrice != null && originalPrice! > price) {
      return (originalPrice! - price) * quantity;
    }
    return 0.0;
  }

  // Check if item has discount
  bool get hasDiscount {
    return originalPrice != null && originalPrice! > price;
  }

  // Get discount percentage
  double get discountPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice!) * 100;
    }
    return 0.0;
  }

  // Get formatted quantity display for the product package
  String get formattedProductQuantity {
    if (quantityDisplay != null && quantityDisplay!.isNotEmpty) {
      return quantityDisplay!;
    }

    if (productQuantity != null && productUnit != null) {
      String quantityStr = productQuantity! % 1 == 0
          ? productQuantity!.toInt().toString()
          : productQuantity!.toString();

      return '$quantityStr $productUnit';
    }

    return '';
  }

  // Get total product quantity (cart quantity × package quantity)
  double? get totalProductQuantity {
    if (productQuantity != null) {
      return productQuantity! * quantity;
    }
    return null;
  }

  // Get formatted total quantity
  String get formattedTotalQuantity {
    if (totalProductQuantity != null && productUnit != null) {
      String quantityStr = totalProductQuantity! % 1 == 0
          ? totalProductQuantity!.toInt().toString()
          : totalProductQuantity!.toString();

      return '$quantityStr $productUnit total';
    }
    return '';
  }

  // Get price per unit
  double? get pricePerUnit {
    if (productQuantity != null && productQuantity! > 0) {
      return price / productQuantity!;
    }
    return null;
  }

  // Get formatted price per unit
  String get formattedPricePerUnit {
    if (pricePerUnit != null && productUnit != null) {
      return '₹${pricePerUnit!.toStringAsFixed(2)}/${productUnit}';
    }
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'productQuantity': productQuantity,
      'productUnit': productUnit,
      'quantityDisplay': quantityDisplay,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      originalPrice: map['originalPrice']?.toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      productQuantity: map['productQuantity']?.toDouble(),
      productUnit: map['productUnit'],
      quantityDisplay: map['quantityDisplay'],
    );
  }

  // Copy with method for easy updates
  CartItemModel copyWith({
    String? productId,
    String? name,
    double? price,
    double? originalPrice,
    String? imageUrl,
    int? quantity,
    double? productQuantity,
    String? productUnit,
    String? quantityDisplay,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      productQuantity: productQuantity ?? this.productQuantity,
      productUnit: productUnit ?? this.productUnit,
      quantityDisplay: quantityDisplay ?? this.quantityDisplay,
    );
  }
}

// New model for discount details
class DiscountDetail {
  final String productName;
  final double originalPrice;
  final double discountedPrice;
  final int quantity;
  final double savingsAmount;
  final double discountPercentage;

  DiscountDetail({
    required this.productName,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.savingsAmount,
    required this.discountPercentage,
  });

  factory DiscountDetail.fromMap(Map<String, dynamic> map) {
    return DiscountDetail(
      productName: map['productName'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (map['discountedPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      savingsAmount: (map['savingsAmount'] ?? 0).toDouble(),
      discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'savingsAmount': savingsAmount,
      'discountPercentage': discountPercentage,
    };
  }
}

// OrderModel with Firestore Timestamp support
class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double total;
  final double? originalTotal;
  final double? totalSavings;
  final bool hasDiscounts;
  final Map<String, dynamic> shippingAddress;
  final Map<String, dynamic> customerDetails;
  final String status;
  final String paymentStatus;
  final String? shippingStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? delhivery; // Add this field
  final Map<String, dynamic>? paymentData;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    this.originalTotal,
    this.totalSavings,
    this.hasDiscounts = false,
    required this.shippingAddress,
    required this.customerDetails,
    required this.status,
    required this.paymentStatus,
    this.shippingStatus,
    required this.createdAt,
    this.updatedAt,
    this.delhivery, // Add this parameter
    this.paymentData,
  });

  // Update the fromMap factory constructor
  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map(
                  (item) => CartItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] ?? 0).toDouble(),
      originalTotal: map['originalTotal']?.toDouble(),
      totalSavings: map['totalSavings']?.toDouble(),
      hasDiscounts: map['hasDiscounts'] ?? false,
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] ?? {}),
      customerDetails: Map<String, dynamic>.from(map['customerDetails'] ?? {}),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      shippingStatus: map['shippingStatus'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      delhivery: map['delhivery'] != null
          ? Map<String, dynamic>.from(map['delhivery'])
          : null, // Add this line
      paymentData: map['paymentData'] != null
          ? Map<String, dynamic>.from(map['paymentData'])
          : null,
    );
  }

  // Update the toMap method
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'originalTotal': originalTotal,
      'totalSavings': totalSavings,
      'hasDiscounts': hasDiscounts,
      'shippingAddress': shippingAddress,
      'customerDetails': customerDetails,
      'status': status,
      'paymentStatus': paymentStatus,
      'shippingStatus': shippingStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'delhivery': delhivery, // Add this line
      'paymentData': paymentData,
    };
  }

  // Add copyWith method if you don't have one
  OrderModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    double? total,
    double? originalTotal,
    double? totalSavings,
    bool? hasDiscounts,
    Map<String, dynamic>? shippingAddress,
    Map<String, dynamic>? customerDetails,
    String? status,
    String? paymentStatus,
    String? shippingStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? delhivery, // Add this parameter
    Map<String, dynamic>? paymentData,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      originalTotal: originalTotal ?? this.originalTotal,
      totalSavings: totalSavings ?? this.totalSavings,
      hasDiscounts: hasDiscounts ?? this.hasDiscounts,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      customerDetails: customerDetails ?? this.customerDetails,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingStatus: shippingStatus ?? this.shippingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      delhivery: delhivery ?? this.delhivery, // Add this line
      paymentData: paymentData ?? this.paymentData,
    );
  }
}
