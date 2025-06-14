// providers/review_provider.dart - COMPLETE FULL CODE
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io' show File;
import '../models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, List<ReviewModel>> _productReviews = {};
  Map<String, ReviewStatistics> _reviewStatistics = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get reviews for a specific product
  List<ReviewModel> getProductReviews(String productId) {
    return _productReviews[productId] ?? [];
  }

  // Get review statistics for a product
  ReviewStatistics getProductReviewStatistics(String productId) {
    return _reviewStatistics[productId] ?? ReviewStatistics.fromReviews([]);
  }

  // Load reviews for a specific product
  Future<void> loadProductReviews(String productId) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔍 Loading reviews for product: $productId');

      final snapshot = await _database
          .child('reviews')
          .orderByChild('productId')
          .equalTo(productId)
          .get();

      List<ReviewModel> reviews = [];
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        reviews = data.entries
            .map((entry) => ReviewModel.fromMap(
                Map<String, dynamic>.from(entry.value), entry.key))
            .toList();

        // Sort by creation date (newest first)
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('✅ Loaded ${reviews.length} reviews for product $productId');
      } else {
        print('📭 No reviews found for product $productId');
      }

      _productReviews[productId] = reviews;
      _reviewStatistics[productId] = ReviewStatistics.fromReviews(reviews);
    } catch (e) {
      print('❌ Error loading reviews: $e');
      _setError('Failed to load reviews: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Check if current user can review a product
  Future<Map<String, dynamic>> canUserReviewProduct(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'canReview': false,
        'reason': 'User not logged in',
        'hasOrdered': false,
        'hasReviewed': false,
      };
    }

    try {
      print('🔍 Checking review eligibility for user: ${user.uid}');
      print('📦 Product ID: $productId');

      // First check if user has already reviewed this product
      final existingReviews = _productReviews[productId] ?? [];
      bool hasReviewed =
          existingReviews.any((review) => review.userId == user.uid);

      // If not in cache, check database directly
      if (!hasReviewed && existingReviews.isEmpty) {
        final reviewSnapshot = await _database
            .child('reviews')
            .orderByChild('productId')
            .equalTo(productId)
            .limitToFirst(100)
            .get();

        if (reviewSnapshot.exists) {
          final reviews =
              Map<String, dynamic>.from(reviewSnapshot.value as Map);
          hasReviewed =
              reviews.values.any((review) => review['userId'] == user.uid);
        }
      }

      if (hasReviewed) {
        print('❌ User has already reviewed this product');
        return {
          'canReview': false,
          'reason': 'You have already reviewed this product',
          'hasOrdered': true,
          'hasReviewed': true,
        };
      }

      // Check orders using Firestore
      print('🔍 Checking orders in Firestore for user: ${user.uid}');

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      bool hasOrdered = false;
      String? orderId;

      print('📋 Found ${ordersSnapshot.docs.length} completed orders');

      for (final orderDoc in ordersSnapshot.docs) {
        final order = orderDoc.data();
        final items = List<dynamic>.from(order['items'] ?? []);

        print('🔎 Checking order ${orderDoc.id} with ${items.length} items');

        // Check if this order contains the product
        bool containsProduct = items.any((item) {
          final productIdInOrder = item['productId'] as String?;
          return productIdInOrder == productId;
        });

        if (containsProduct) {
          print('✅ Found product in order ${orderDoc.id}');

          final status = order['status'] as String?;
          final shippingStatus = order['shippingStatus'] as String?;
          final paymentStatus = order['paymentStatus'] as String?;

          print('📦 Order status: $status');
          print('🚚 Shipping status: $shippingStatus');
          print('💳 Payment status: $paymentStatus');

          // Allow reviews for orders that are paid and shipped
          bool canReview = paymentStatus == 'completed' &&
              (status == 'delivered' ||
                  status == 'confirmed' ||
                  shippingStatus == 'delivered' ||
                  shippingStatus == 'manifested' ||
                  shippingStatus == 'shipped' ||
                  shippingStatus == 'in_transit' ||
                  shippingStatus == 'out_for_delivery');

          if (canReview) {
            hasOrdered = true;
            orderId = orderDoc.id;
            print('✅ User can review - order is paid and shipped/delivered');
            break;
          } else {
            print('⏳ Order found but not yet eligible for review');
          }
        }
      }

      if (!hasOrdered) {
        print('❌ No eligible orders found for review');
        return {
          'canReview': false,
          'reason':
              'You need to purchase and receive this product before reviewing',
          'hasOrdered': false,
          'hasReviewed': false,
        };
      }

      print('✅ User can review this product');
      return {
        'canReview': true,
        'reason': 'You can review this product',
        'hasOrdered': true,
        'hasReviewed': false,
        'orderId': orderId,
      };
    } catch (e) {
      print('❌ Error checking review eligibility: $e');
      return {
        'canReview': false,
        'reason': 'Error checking review eligibility. Please try again.',
        'hasOrdered': false,
        'hasReviewed': false,
      };
    }
  }

  // Add a new review with web-compatible image handling
  Future<bool> addReview({
    required String productId,
    required double rating,
    String? reviewText,
    List<XFile>? images,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      print('📝 Attempting to add review');

      // Check if user can review
      final canReview = await canUserReviewProduct(productId);
      if (!canReview['canReview']) {
        _setError(canReview['reason']);
        return false;
      }

      // Get user name - try multiple sources
      String userName = 'Anonymous User';
      try {
        // First try Firestore users collection
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userName = userData['name'] ??
              userData['displayName'] ??
              user.displayName ??
              'Anonymous User';
        } else {
          // Try Realtime Database
          final userSnapshot = await _database.child('users/${user.uid}').get();
          if (userSnapshot.exists) {
            final userData =
                Map<String, dynamic>.from(userSnapshot.value as Map);
            userName = userData['name'] ?? user.displayName ?? 'Anonymous User';
          } else {
            // Fallback to Firebase Auth
            userName = user.displayName ??
                user.email?.split('@')[0] ??
                'Anonymous User';
          }
        }
      } catch (e) {
        print('❌ Error getting user name: $e');
        userName = user.displayName ?? 'Anonymous User';
      }

      print('👤 User name for review: $userName');

      // Upload images if provided (web-compatible)
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        imageUrls = await _uploadReviewImagesWeb(productId, user.uid, images);
      }

      // Create review
      final reviewRef = _database.child('reviews').push();
      final review = ReviewModel(
        id: reviewRef.key!,
        userId: user.uid,
        userName: userName,
        productId: productId,
        rating: rating,
        reviewText:
            reviewText?.trim().isEmpty == true ? null : reviewText?.trim(),
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        isVerifiedPurchase: true,
        orderId: canReview['orderId'],
      );

      await reviewRef.set(review.toMap());

      // Update local cache
      await loadProductReviews(productId);

      // Update product rating in products table
      await _updateProductRating(productId);

      print('✅ Review added successfully');
      return true;
    } catch (e) {
      print('❌ Error adding review: $e');
      _setError('Failed to add review: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Web-compatible image upload method
  Future<List<String>> _uploadReviewImagesWeb(
      String productId, String userId, List<XFile> images) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'review_${productId}_${userId}_${timestamp}_$i.jpg';
        final ref = _storage.ref().child('reviews/$productId/$fileName');

        late UploadTask uploadTask;

        if (kIsWeb) {
          // Web: Use Uint8List
          final Uint8List imageData = await images[i].readAsBytes();
          uploadTask = ref.putData(imageData);
        } else {
          // Mobile: Use File
          final File file = File(images[i].path);
          uploadTask = ref.putFile(file);
        }

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
        print('✅ Uploaded image ${i + 1}/${images.length}');
      } catch (e) {
        print('❌ Error uploading image $i: $e');
        // Continue with other images even if one fails
      }
    }

    return urls;
  }

  // Update product's average rating
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = _productReviews[productId] ?? [];
      if (reviews.isEmpty) return;

      final statistics = ReviewStatistics.fromReviews(reviews);

      print(
          '📊 Updating product rating: ${statistics.averageRating} (${statistics.totalReviews} reviews)');

      // Update in Realtime Database (if you're using it for products)
      await _database.child('products/$productId').update({
        'rating': statistics.averageRating,
        'reviewCount': statistics.totalReviews,
        'lastReviewUpdate': DateTime.now().millisecondsSinceEpoch,
      });

      // Also update in Firestore if you're using it for products
      try {
        await _firestore.collection('products').doc(productId).update({
          'rating': statistics.averageRating,
          'reviewCount': statistics.totalReviews,
          'lastReviewUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ Updated product rating in both databases');
      } catch (e) {
        print('⚠️ Could not update Firestore product rating: $e');
        // This is okay if you're only using Realtime Database for products
      }
    } catch (e) {
      print('❌ Error updating product rating: $e');
    }
  }

  // Get user's review for a product
  Future<ReviewModel?> getUserReviewForProduct(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // First check in cached reviews
      final cachedReviews = _productReviews[productId] ?? [];
      final userReview = cachedReviews
          .where((review) => review.userId == user.uid)
          .firstOrNull;

      if (userReview != null) {
        return userReview;
      }

      // If not in cache, load the product reviews
      if (cachedReviews.isEmpty) {
        await loadProductReviews(productId);
        final updatedReviews = _productReviews[productId] ?? [];
        return updatedReviews
            .where((review) => review.userId == user.uid)
            .firstOrNull;
      }
    } catch (e) {
      print('Error getting user review: $e');
    }

    return null;
  }

  // Update existing review with web-compatible images
  Future<bool> updateReview({
    required String reviewId,
    required double rating,
    String? reviewText,
    List<XFile>? newImages,
    List<String>? existingImageUrls,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      // Get existing review to verify ownership
      final reviewSnapshot = await _database.child('reviews/$reviewId').get();
      if (!reviewSnapshot.exists) {
        _setError('Review not found');
        return false;
      }

      final existingReview = ReviewModel.fromMap(
          Map<String, dynamic>.from(reviewSnapshot.value as Map), reviewId);

      if (existingReview.userId != user.uid) {
        _setError('You can only edit your own reviews');
        return false;
      }

      // Handle images
      List<String> finalImageUrls = List.from(existingImageUrls ?? []);

      // Upload new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        final newUrls = await _uploadReviewImagesWeb(
            existingReview.productId, user.uid, newImages);
        finalImageUrls.addAll(newUrls);
      }

      // Update review
      final updatedData = {
        'rating': rating,
        'reviewText':
            reviewText?.trim().isEmpty == true ? null : reviewText?.trim(),
        'imageUrls': finalImageUrls,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _database.child('reviews/$reviewId').update(updatedData);

      // Refresh local cache
      await loadProductReviews(existingReview.productId);

      // Update product rating
      await _updateProductRating(existingReview.productId);

      return true;
    } catch (e) {
      _setError('Failed to update review: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      // Get existing review to verify ownership
      final reviewSnapshot = await _database.child('reviews/$reviewId').get();
      if (!reviewSnapshot.exists) {
        _setError('Review not found');
        return false;
      }

      final existingReview = ReviewModel.fromMap(
          Map<String, dynamic>.from(reviewSnapshot.value as Map), reviewId);

      if (existingReview.userId != user.uid) {
        _setError('You can only delete your own reviews');
        return false;
      }

      // Delete review images from storage
      for (final imageUrl in existingReview.imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      // Delete review from database
      await _database.child('reviews/$reviewId').remove();

      // Refresh local cache
      await loadProductReviews(existingReview.productId);

      // Update product rating
      await _updateProductRating(existingReview.productId);

      return true;
    } catch (e) {
      _setError('Failed to delete review: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sort and filter reviews
  List<ReviewModel> getSortedAndFilteredReviews(
    String productId, {
    ReviewSortOption sortOption = ReviewSortOption.newest,
    ReviewFilter? filter,
  }) {
    List<ReviewModel> reviews = List.from(_productReviews[productId] ?? []);

    // Apply filters
    if (filter != null) {
      reviews = reviews.where((review) => filter.matches(review)).toList();
    }

    // Apply sorting
    switch (sortOption) {
      case ReviewSortOption.newest:
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ReviewSortOption.oldest:
        reviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ReviewSortOption.highestRated:
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSortOption.lowestRated:
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ReviewSortOption.verifiedFirst:
        reviews.sort((a, b) {
          if (a.isVerifiedPurchase && !b.isVerifiedPurchase) return -1;
          if (!a.isVerifiedPurchase && b.isVerifiedPurchase) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case ReviewSortOption.withPhotos:
        reviews.sort((a, b) {
          if (a.imageUrls.isNotEmpty && b.imageUrls.isEmpty) return -1;
          if (a.imageUrls.isEmpty && b.imageUrls.isNotEmpty) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return reviews;
  }

  // Get reviews by user
  Future<List<ReviewModel>> getUserReviews() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get all reviews and filter by user
      final snapshot = await _database.child('reviews').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries
            .where((entry) {
              final reviewData = Map<String, dynamic>.from(entry.value);
              return reviewData['userId'] == user.uid;
            })
            .map((entry) => ReviewModel.fromMap(
                Map<String, dynamic>.from(entry.value), entry.key))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      print('Error getting user reviews: $e');
    }

    return [];
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear cache for a product
  void clearProductReviews(String productId) {
    _productReviews.remove(productId);
    _reviewStatistics.remove(productId);
    notifyListeners();
  }

  // Clear all cached data
  void clearAllReviews() {
    _productReviews.clear();
    _reviewStatistics.clear();
    notifyListeners();
  }

  // Refresh reviews after user action
  Future<void> refreshProductReviews(String productId) async {
    await loadProductReviews(productId);
  }

  // Get statistics without loading if already cached
  ReviewStatistics? getCachedReviewStatistics(String productId) {
    return _reviewStatistics[productId];
  }

  // Check if reviews are loaded for a product
  bool areReviewsLoaded(String productId) {
    return _productReviews.containsKey(productId);
  }

  // Get review count for a product
  int getReviewCount(String productId) {
    return _productReviews[productId]?.length ?? 0;
  }

  // Get average rating for a product
  double getAverageRating(String productId) {
    final reviews = _productReviews[productId];
    if (reviews == null || reviews.isEmpty) return 0.0;

    final total =
        reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  // Check if user has reviewed a specific product (quick check)
  bool hasUserReviewed(String productId, String userId) {
    final reviews = _productReviews[productId] ?? [];
    return reviews.any((review) => review.userId == userId);
  }

  // Get verified purchase reviews only
  List<ReviewModel> getVerifiedReviews(String productId) {
    final reviews = _productReviews[productId] ?? [];
    return reviews.where((review) => review.isVerifiedPurchase).toList();
  }

  // Get reviews with images only
  List<ReviewModel> getReviewsWithImages(String productId) {
    final reviews = _productReviews[productId] ?? [];
    return reviews.where((review) => review.imageUrls.isNotEmpty).toList();
  }

  // Get recent reviews (last 30 days)
  List<ReviewModel> getRecentReviews(String productId) {
    final reviews = _productReviews[productId] ?? [];
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return reviews
        .where((review) => review.createdAt.isAfter(thirtyDaysAgo))
        .toList();
  }

  // Bulk load reviews for multiple products
  Future<void> loadMultipleProductReviews(List<String> productIds) async {
    for (final productId in productIds) {
      if (!_productReviews.containsKey(productId)) {
        await loadProductReviews(productId);
      }
    }
  }

  // Get popular reviews (high rating with recent activity)
  List<ReviewModel> getPopularReviews(String productId) {
    final reviews = _productReviews[productId] ?? [];
    return reviews.where((review) => review.rating >= 4.0).toList()
      ..sort((a, b) {
        // Sort by rating first, then by date
        final ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) return ratingComparison;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  // Get review distribution by rating
  Map<int, int> getReviewDistribution(String productId) {
    final reviews = _productReviews[productId] ?? [];
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final review in reviews) {
      final starCount = review.starCount;
      distribution[starCount] = (distribution[starCount] ?? 0) + 1;
    }

    return distribution;
  }

  // Search reviews by text content
  List<ReviewModel> searchReviews(String productId, String searchTerm) {
    final reviews = _productReviews[productId] ?? [];
    final lowerSearchTerm = searchTerm.toLowerCase();

    return reviews.where((review) {
      final reviewText = review.reviewText?.toLowerCase() ?? '';
      final userName = review.userName.toLowerCase();
      return reviewText.contains(lowerSearchTerm) ||
          userName.contains(lowerSearchTerm);
    }).toList();
  }

  // Get review summary for quick display
  Map<String, dynamic> getReviewSummary(String productId) {
    final statistics = getProductReviewStatistics(productId);
    return {
      'total_reviews': statistics.totalReviews,
      'average_rating': statistics.averageRating,
      'verified_count': statistics.verifiedReviewsCount,
      'has_recent_reviews': getRecentReviews(productId).isNotEmpty,
      'has_images': getReviewsWithImages(productId).isNotEmpty,
      'rating_distribution': getReviewDistribution(productId),
    };
  }
}

// Extension to safely get first element or null
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
