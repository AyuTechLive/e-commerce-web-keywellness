// widgets/review_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/review_model.dart';
import '../providers/review_provider.dart';

// Main Review Section Widget
class ProductReviewSection extends StatefulWidget {
  final String productId;

  const ProductReviewSection({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductReviewSection> createState() => _ProductReviewSectionState();
}

class _ProductReviewSectionState extends State<ProductReviewSection> {
  ReviewSortOption _sortOption = ReviewSortOption.newest;
  ReviewFilter _filter = ReviewFilter();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = reviewProvider.getSortedAndFilteredReviews(
          widget.productId,
          sortOption: _sortOption,
          filter: _filter,
        );
        final statistics =
            reviewProvider.getProductReviewStatistics(widget.productId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Statistics
            ReviewStatisticsWidget(statistics: statistics),

            const SizedBox(height: 24),

            // Add Review Button
            AddReviewButton(productId: widget.productId),

            const SizedBox(height: 24),

            // Filters and Sort
            _buildFiltersAndSort(statistics.totalReviews),

            const SizedBox(height: 16),

            // Reviews List
            if (reviewProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                  ),
                ),
              )
            else if (reviews.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: reviews
                    .map((review) =>
                        ReviewCard(review: review, productId: widget.productId))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersAndSort(int totalReviews) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Reviews ($totalReviews)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              // Sort Dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<ReviewSortOption>(
                  value: _sortOption,
                  onChanged: (option) {
                    if (option != null) {
                      setState(() {
                        _sortOption = option;
                      });
                    }
                  },
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 16),
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  items: ReviewSortOption.values
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color:
                      _showFilters ? const Color(0xFF00D4AA) : Colors.grey[600],
                ),
              ),
            ],
          ),

          // Filter Options
          if (_showFilters) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildFilterOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Star Rating Filter
        _buildFilterChip(
          'All Ratings',
          _filter.starRating == null,
          () => setState(() => _filter = _filter.copyWith(starRating: null)),
        ),
        ...List.generate(5, (index) {
          final stars = 5 - index;
          return _buildFilterChip(
            '$stars★',
            _filter.starRating == stars,
            () => setState(() => _filter = _filter.copyWith(starRating: stars)),
          );
        }),

        // Other Filters
        _buildFilterChip(
          'Verified Only',
          _filter.verifiedOnly == true,
          () => setState(() => _filter = _filter.copyWith(
              verifiedOnly: _filter.verifiedOnly == true ? null : true)),
        ),
        _buildFilterChip(
          'With Photos',
          _filter.withPhotosOnly == true,
          () => setState(() => _filter = _filter.copyWith(
              withPhotosOnly: _filter.withPhotosOnly == true ? null : true)),
        ),
        _buildFilterChip(
          'With Text',
          _filter.withTextOnly == true,
          () => setState(() => _filter = _filter.copyWith(
              withTextOnly: _filter.withTextOnly == true ? null : true)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4AA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this product!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// Review Statistics Widget
class ReviewStatisticsWidget extends StatelessWidget {
  final ReviewStatistics statistics;

  const ReviewStatisticsWidget({Key? key, required this.statistics})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  statistics.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: index < statistics.averageRating
                                ? const Color(0xFFFFB300)
                                : Colors.grey[300],
                          )),
                ),
                const SizedBox(height: 4),
                Text(
                  '${statistics.totalReviews} reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (statistics.verifiedReviewsCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${statistics.verificationPercentage.toStringAsFixed(0)}% verified',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00D4AA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Rating Distribution
          Expanded(
            flex: 2,
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final count = statistics.ratingDistribution[stars] ?? 0;
                final percentage = statistics.getStarPercentage(stars);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star,
                          size: 12, color: Color(0xFFFFB300)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D4AA),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          count.toString(),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Review Button
class AddReviewButton extends StatelessWidget {
  final String productId;

  const AddReviewButton({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: reviewProvider.canUserReviewProduct(productId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                  ),
                ),
              );
            }

            final canReview = snapshot.data!;

            if (canReview['canReview'] == true) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddReviewDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.rate_review, color: Colors.white),
                  label: const Text(
                    'Write a Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            } else if (canReview['hasReviewed'] == true) {
              return FutureBuilder<ReviewModel?>(
                future: reviewProvider.getUserReviewForProduct(productId),
                builder: (context, reviewSnapshot) {
                  if (reviewSnapshot.hasData && reviewSnapshot.data != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'You have already reviewed this product',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showEditReviewDialog(
                                context, reviewSnapshot.data!),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            } else {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        canReview['reason'] ?? 'Cannot review this product',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEditReviewDialog(
        productId: productId,
        mode: ReviewDialogMode.add,
      ),
    );
  }

  void _showEditReviewDialog(BuildContext context, ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => AddEditReviewDialog(
        productId: productId,
        mode: ReviewDialogMode.edit,
        existingReview: review,
      ),
    );
  }
}

// Individual Review Card
class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String productId;

  const ReviewCard({Key? key, required this.review, required this.productId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF00D4AA),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Verified Purchase',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Star Rating
                        Row(
                          children: List.generate(
                              5,
                              (index) => Icon(
                                    Icons.star,
                                    size: 14,
                                    color: index < review.starCount
                                        ? const Color(0xFFFFB300)
                                        : Colors.grey[300],
                                  )),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.ratingDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Options Menu (for user's own reviews)
              Consumer<ReviewProvider>(
                builder: (context, reviewProvider, child) {
                  return FutureBuilder<ReviewModel?>(
                    future: reviewProvider.getUserReviewForProduct(productId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data?.id == review.id) {
                        return PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(context);
                            } else if (value == 'delete') {
                              _showDeleteDialog(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox();
                    },
                  );
                },
              ),
            ],
          ),

          // Review Content
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF666666),
              ),
            ),
          ],

          // Review Images
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        _showImageDialog(context, review.imageUrls, index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEditReviewDialog(
        productId: productId,
        mode: ReviewDialogMode.edit,
        existingReview: review,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
            'Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await context.read<ReviewProvider>().deleteReview(review.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Review deleted successfully'
                        : 'Failed to delete review'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Add/Edit Review Dialog
enum ReviewDialogMode { add, edit }

class AddEditReviewDialog extends StatefulWidget {
  final String productId;
  final ReviewDialogMode mode;
  final ReviewModel? existingReview;

  const AddEditReviewDialog({
    Key? key,
    required this.productId,
    required this.mode,
    this.existingReview,
  }) : super(key: key);

  @override
  State<AddEditReviewDialog> createState() => _AddEditReviewDialogState();
}

class _AddEditReviewDialogState extends State<AddEditReviewDialog> {
  final _textController = TextEditingController();
  double _rating = 5.0;
  List<XFile> _newImages = []; // Changed from List<File> to List<XFile>
  List<String> _existingImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == ReviewDialogMode.edit && widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _textController.text = widget.existingReview!.reviewText ?? '';
      _existingImages = List.from(widget.existingReview!.imageUrls);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.mode == ReviewDialogMode.add
                      ? 'Write Review'
                      : 'Edit Review',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating
                    const Text(
                      'Rating *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1.0),
                          child: Icon(
                            Icons.star,
                            size: 32,
                            color: index < _rating
                                ? const Color(0xFFFFB300)
                                : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRatingDescription(_rating.toInt()),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Review Text
                    const Text(
                      'Review Text (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this product...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF00D4AA)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Images
                    const Text(
                      'Photos (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Existing Images
                    if (_existingImages.isNotEmpty) ...[
                      const Text(
                        'Current Photos:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _existingImages[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _existingImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New Images
                    if (_newImages.isNotEmpty) ...[
                      const Text(
                        'New Photos:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FutureBuilder<Uint8List>(
                                        future: _newImages[index].readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _newImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add Photo Button
                    if (_newImages.length + _existingImages.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF00D4AA),
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: Color(0xFF00D4AA),
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF00D4AA),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_newImages.length + _existingImages.length >= 5)
                      Text(
                        'Maximum 5 photos allowed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.mode == ReviewDialogMode.add
                                ? 'Submit Review'
                                : 'Update Review',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        // Limit total images to 5
        final remaining = 5 - (_newImages.length + _existingImages.length);
        final imagesToAdd = images.take(remaining).toList();
        _newImages.addAll(imagesToAdd);
      });
    }
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
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

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final reviewProvider = context.read<ReviewProvider>();
      bool success = false;

      if (widget.mode == ReviewDialogMode.add) {
        success = await reviewProvider.addReview(
          productId: widget.productId,
          rating: _rating,
          reviewText: _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
          images: _newImages.isEmpty ? null : _newImages,
        );
      } else {
        success = await reviewProvider.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _rating,
          reviewText: _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
          newImages: _newImages.isEmpty ? null : _newImages,
          existingImageUrls: _existingImages,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.mode == ReviewDialogMode.add
                    ? 'Review added successfully!'
                    : 'Review updated successfully!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          final error = reviewProvider.error ?? 'Something went wrong';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
