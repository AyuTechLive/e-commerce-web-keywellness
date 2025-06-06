class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final bool inStock;
  final List<String> tags;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.inStock = true,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      categoryId: map['categoryId'] ?? '',
      inStock: map['inStock'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'inStock': inStock,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
