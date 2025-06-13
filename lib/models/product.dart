// models/product.dart - Enhanced with quantity, unit, and multi-category support
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // Add original price for discount calculation
  final String imageUrl;
  final String categoryId; // Primary category (for backward compatibility)
  final List<String> categoryIds; // Multi-category assignment
  final bool inStock;
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final bool hasDiscount; // Add discount flag
  final double? discountPercentage; // Add discount percentage

  // New quantity and unit fields
  final double? quantity; // e.g., 500, 30, 1
  final String? unit; // e.g., "ml", "gm", "capsule", "tablet", "kg", "pieces"
  final String? quantityDisplay; // Combined display like "500ml", "30 capsules"

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.categoryId, // Primary category
    this.categoryIds = const [], // Additional categories
    this.inStock = true,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.hasDiscount = false,
    this.discountPercentage,
    this.quantity,
    this.unit,
    this.quantityDisplay,
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

  // Get formatted quantity display
  String get formattedQuantity {
    if (quantityDisplay != null && quantityDisplay!.isNotEmpty) {
      return quantityDisplay!;
    }

    if (quantity != null && unit != null) {
      // Format based on unit type
      String quantityStr = quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toString();

      return '$quantityStr $unit';
    }

    return '';
  }

  // Get all category IDs (primary + additional)
  List<String> get allCategoryIds {
    Set<String> allIds = {categoryId};
    allIds.addAll(categoryIds);
    return allIds.toList();
  }

  // Check if product belongs to a category
  bool belongsToCategory(String categoryId) {
    return allCategoryIds.contains(categoryId);
  }

  // Get unit type for better categorization
  ProductUnitType get unitType {
    if (unit == null) return ProductUnitType.other;

    final unitLower = unit!.toLowerCase();

    if (['ml', 'l', 'liter', 'litre'].contains(unitLower)) {
      return ProductUnitType.liquid;
    } else if (['gm', 'g', 'kg', 'gram', 'kilogram'].contains(unitLower)) {
      return ProductUnitType.weight;
    } else if (['capsule', 'tablet', 'cap', 'tab', 'pill']
        .contains(unitLower)) {
      return ProductUnitType.medicine;
    } else if (['pieces', 'pcs', 'piece', 'nos', 'units'].contains(unitLower)) {
      return ProductUnitType.pieces;
    }

    return ProductUnitType.other;
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final originalPrice = map['originalPrice']?.toDouble();
    final price = (map['price'] ?? 0).toDouble();

    // Handle category IDs for multi-category support
    String primaryCategoryId = map['categoryId'] ?? '';
    List<String> additionalCategoryIds = [];

    if (map['categoryIds'] != null) {
      additionalCategoryIds = List<String>.from(map['categoryIds']);
    }

    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: price,
      originalPrice: originalPrice,
      imageUrl: map['imageUrl'] ?? '',
      categoryId: primaryCategoryId,
      categoryIds: additionalCategoryIds,
      inStock: map['inStock'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      hasDiscount: map['hasDiscount'] ?? false,
      discountPercentage: map['discountPercentage']?.toDouble(),
      quantity: map['quantity']?.toDouble(),
      unit: map['unit'],
      quantityDisplay: map['quantityDisplay'],
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
      'categoryIds': categoryIds,
      'inStock': inStock,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'quantity': quantity,
      'unit': unit,
      'quantityDisplay': quantityDisplay,
    };
  }

  // Copy with method for easy updates
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? categoryId,
    List<String>? categoryIds,
    bool? inStock,
    List<String>? tags,
    double? rating,
    int? reviewCount,
    bool? hasDiscount,
    double? discountPercentage,
    double? quantity,
    String? unit,
    String? quantityDisplay,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryIds: categoryIds ?? this.categoryIds,
      inStock: inStock ?? this.inStock,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      quantityDisplay: quantityDisplay ?? this.quantityDisplay,
    );
  }
}

// Enum for different unit types
enum ProductUnitType {
  liquid, // ml, l
  weight, // gm, kg
  medicine, // capsule, tablet
  pieces, // pieces, nos
  other // custom units
}

// Helper class for unit validation and suggestions
class ProductUnitHelper {
  static const Map<ProductUnitType, List<String>> unitSuggestions = {
    ProductUnitType.liquid: ['ml', 'l', 'liter'],
    ProductUnitType.weight: ['gm', 'g', 'kg'],
    ProductUnitType.medicine: ['capsule', 'tablet', 'cap', 'tab'],
    ProductUnitType.pieces: ['pieces', 'pcs', 'nos', 'units'],
  };

  static const List<String> commonUnits = [
    'ml',
    'l',
    'gm',
    'g',
    'kg',
    'capsule',
    'tablet',
    'pieces',
    'nos',
    'units',
    'bottle',
    'pack',
    'box'
  ];

  static List<String> getUnitSuggestions(ProductUnitType type) {
    return unitSuggestions[type] ?? [];
  }

  static bool isValidUnit(String unit) {
    return commonUnits.contains(unit.toLowerCase()) || unit.isNotEmpty;
  }

  static String formatQuantityUnit(double quantity, String unit) {
    String quantityStr =
        quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();

    return '$quantityStr $unit';
  }
}
