class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // Add original price for discount calculation
  final String imageUrl;
  final String categoryId;
  final bool inStock;
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final bool hasDiscount; // Add discount flag
  final double? discountPercentage; // Add discount percentage

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.categoryId,
    this.inStock = true,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.hasDiscount = false,
    this.discountPercentage,
  });

  // Calculate discount percentage if originalPrice exists
  double get calculatedDiscountPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice!) * 100;
    }
    return 0.0;
  }

  // Get savings amount
  double get savingsAmount {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice! - price;
    }
    return 0.0;
  }

  // Check if product is on sale
  bool get isOnSale {
    return hasDiscount || (originalPrice != null && originalPrice! > price);
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final originalPrice = map['originalPrice']?.toDouble();
    final price = (map['price'] ?? 0).toDouble();

    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: price,
      originalPrice: originalPrice,
      imageUrl: map['imageUrl'] ?? '',
      categoryId: map['categoryId'] ?? '',
      inStock: map['inStock'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      hasDiscount: map['hasDiscount'] ?? false,
      discountPercentage: map['discountPercentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'inStock': inStock,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
    };
  }
}
