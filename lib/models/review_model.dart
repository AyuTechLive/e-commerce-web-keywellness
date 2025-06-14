// models/review_model.dart
class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final double rating; // 1-5 stars (required)
  final String? reviewText; // Optional text review
  final List<String> imageUrls; // Optional review images
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool
      isVerifiedPurchase; // Only true if user actually ordered the product
  final String? orderId; // Reference to the order that allows this review

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    required this.rating,
    this.reviewText,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.isVerifiedPurchase = false,
    this.orderId,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      productId: map['productId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewText: map['reviewText'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
      orderId: map['orderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'productId': productId,
      'rating': rating,
      'reviewText': reviewText,
      'imageUrls': imageUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isVerifiedPurchase': isVerifiedPurchase,
      'orderId': orderId,
    };
  }

  // Get formatted date for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if review has content (text or images)
  bool get hasContent {
    return (reviewText != null && reviewText!.trim().isNotEmpty) ||
        imageUrls.isNotEmpty;
  }

  // Get star rating as integer for display
  int get starCount => rating.round();

  // Get rating description
  String get ratingDescription {
    switch (starCount) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not Rated';
    }
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? productId,
    double? rating,
    String? reviewText,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerifiedPurchase,
    String? orderId,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReviewModel(id: $id, userId: $userId, productId: $productId, rating: $rating, isVerifiedPurchase: $isVerifiedPurchase)';
  }
}

// Helper class for review statistics
class ReviewStatistics {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution; // star -> count
  final int verifiedReviewsCount;

  ReviewStatistics({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingDistribution,
    required this.verifiedReviewsCount,
  });

  factory ReviewStatistics.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return ReviewStatistics(
        totalReviews: 0,
        averageRating: 0.0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        verifiedReviewsCount: 0,
      );
    }

    final totalRating =
        reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int verifiedCount = 0;

    for (final review in reviews) {
      distribution[review.starCount] =
          (distribution[review.starCount] ?? 0) + 1;
      if (review.isVerifiedPurchase) {
        verifiedCount++;
      }
    }

    return ReviewStatistics(
      totalReviews: reviews.length,
      averageRating: averageRating,
      ratingDistribution: distribution,
      verifiedReviewsCount: verifiedCount,
    );
  }

  // Get percentage for each star rating
  double getStarPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    return ((ratingDistribution[stars] ?? 0) / totalReviews) * 100;
  }

  // Get verification percentage
  double get verificationPercentage {
    if (totalReviews == 0) return 0.0;
    return (verifiedReviewsCount / totalReviews) * 100;
  }
}

// Enum for review sort options
enum ReviewSortOption {
  newest,
  oldest,
  highestRated,
  lowestRated,
  verifiedFirst,
  withPhotos,
}

extension ReviewSortOptionExtension on ReviewSortOption {
  String get label {
    switch (this) {
      case ReviewSortOption.newest:
        return 'Newest First';
      case ReviewSortOption.oldest:
        return 'Oldest First';
      case ReviewSortOption.highestRated:
        return 'Highest Rated';
      case ReviewSortOption.lowestRated:
        return 'Lowest Rated';
      case ReviewSortOption.verifiedFirst:
        return 'Verified Purchases';
      case ReviewSortOption.withPhotos:
        return 'With Photos';
    }
  }
}

// Filter options for reviews
class ReviewFilter {
  final int? starRating; // Filter by specific star rating
  final bool? verifiedOnly; // Show only verified purchases
  final bool? withPhotosOnly; // Show only reviews with photos
  final bool? withTextOnly; // Show only reviews with text

  ReviewFilter({
    this.starRating,
    this.verifiedOnly,
    this.withPhotosOnly,
    this.withTextOnly,
  });

  bool matches(ReviewModel review) {
    if (starRating != null && review.starCount != starRating) {
      return false;
    }
    if (verifiedOnly == true && !review.isVerifiedPurchase) {
      return false;
    }
    if (withPhotosOnly == true && review.imageUrls.isEmpty) {
      return false;
    }
    if (withTextOnly == true &&
        (review.reviewText == null || review.reviewText!.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  ReviewFilter copyWith({
    int? starRating,
    bool? verifiedOnly,
    bool? withPhotosOnly,
    bool? withTextOnly,
  }) {
    return ReviewFilter(
      starRating: starRating ?? this.starRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      withPhotosOnly: withPhotosOnly ?? this.withPhotosOnly,
      withTextOnly: withTextOnly ?? this.withTextOnly,
    );
  }
}
