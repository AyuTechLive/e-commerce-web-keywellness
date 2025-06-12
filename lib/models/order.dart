// models/cart_item_model.dart (renamed to avoid conflicts)
// models/order_model.dart (renamed to avoid conflicts)
class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double total;
  final double? originalTotal; // Add original total before discounts
  final double? totalSavings; // Add total savings amount
  final List<DiscountDetail>? discountDetails; // Add discount details
  final String status;
  final DateTime createdAt;
  final String paymentId;
  final String shippingAddress;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    this.originalTotal,
    this.totalSavings,
    this.discountDetails,
    this.status = 'pending',
    required this.createdAt,
    this.paymentId = '',
    required this.shippingAddress,
  });

  // Check if order has any discounts
  bool get hasDiscounts {
    return totalSavings != null && totalSavings! > 0;
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CartItemModel.fromMap(item))
              .toList() ??
          [],
      total: (map['total'] ?? 0).toDouble(),
      originalTotal: map['originalTotal']?.toDouble(),
      totalSavings: map['totalSavings']?.toDouble(),
      discountDetails: (map['discountDetails'] as List<dynamic>?)
          ?.map((detail) => DiscountDetail.fromMap(detail))
          .toList(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      paymentId: map['paymentId'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'originalTotal': originalTotal,
      'totalSavings': totalSavings,
      'discountDetails':
          discountDetails?.map((detail) => detail.toMap()).toList(),
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paymentId': paymentId,
      'shippingAddress': shippingAddress,
    };
  }
}

// models/cart_item_model.dart (renamed to avoid conflicts)
class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final double? originalPrice; // Add original price for discount tracking
  final String imageUrl;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.quantity = 1,
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

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
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
