// models/order_model.dart (renamed to avoid conflicts)
class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String paymentId;
  final String shippingAddress;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    this.status = 'pending',
    required this.createdAt,
    this.paymentId = '',
    required this.shippingAddress,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CartItemModel(
                    productId: item['productId'],
                    name: item['name'],
                    price: (item['price'] ?? 0).toDouble(),
                    imageUrl: item['imageUrl'],
                    quantity: item['quantity'] ?? 1,
                  ))
              .toList() ??
          [],
      total: (map['total'] ?? 0).toDouble(),
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
  final String imageUrl;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}
