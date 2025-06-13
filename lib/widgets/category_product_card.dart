// widgets/category_card.dart - 100% overflow-proof version
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        return GestureDetector(
          onTap: () => context.go('/category/${category.id}'),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/category/${category.id}'),
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      // Image section - 75% of height for better proportion
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight * 0.75,
                        child:
                            _buildImageContainer(cardWidth, cardHeight * 0.75),
                      ),
                      // Content section - 25% of height
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight * 0.25,
                        child: _buildContentContainer(
                            cardWidth, cardHeight * 0.25),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageContainer(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
          child: Image.network(
            category.imageUrl,
            fit: BoxFit
                .fill, // Fill the entire area completely - no cropping, no shrinking
            width: width,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: (width * 0.15).clamp(20, 40),
                        height: (width * 0.15).clamp(20, 40),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        ),
                      ),
                      SizedBox(height: height * 0.05),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: (width * 0.04).clamp(10, 14),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: (width * 0.2).clamp(30, 60),
                        color: const Color(0xFF2E7D32),
                      ),
                      SizedBox(height: height * 0.05),
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: (width * 0.04).clamp(10, 14),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentContainer(double width, double height) {
    final double padding = (width * 0.04).clamp(8, 16);
    final double contentWidth = width - (padding * 2);
    final double contentHeight = height - (padding * 2);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: _buildCategoryName(contentWidth, contentHeight),
      ),
    );
  }

  Widget _buildCategoryName(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Center(
        child: Text(
          category.name,
          style: TextStyle(
            fontSize: _calculateFontSize(width, height),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E7D32),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: _calculateMaxLines(height),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Calculate optimal font size based on available space
  double _calculateFontSize(double width, double height) {
    // Base font size on both width and height
    final double baseSize = (width * 0.08).clamp(12, 20);
    final double heightConstrainedSize = (height * 0.4).clamp(12, 20);

    // Use the smaller of the two to ensure text fits
    return baseSize < heightConstrainedSize ? baseSize : heightConstrainedSize;
  }

  // Calculate max lines based on available height
  int _calculateMaxLines(double height) {
    if (height < 25) return 1;
    if (height < 45) return 2;
    return 3; // Allow up to 3 lines for very tall cards
  }
}
