// widgets/product_card.dart - Absolutely overflow-proof version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        return GestureDetector(
          onTap: () => context.go('/product/${product.id}'),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Image section - exactly 60% of height
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight * 0.6,
                    child: _buildImageContainer(cardWidth, cardHeight * 0.6),
                  ),
                  // Content section - exactly 40% of height
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight * 0.4,
                    child: _buildContentContainer(cardWidth, cardHeight * 0.4),
                  ),
                ],
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
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          // Background image that fills space without cropping
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: width,
                height: height,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover, // Fill the space completely
                  width: width,
                  height: height,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: width,
                      height: height,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: (width * 0.2).clamp(20, 50),
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: width,
                      height: height,
                      color: Colors.grey[100],
                      child: Center(
                        child: SizedBox(
                          width: (width * 0.15).clamp(16, 30),
                          height: (width * 0.15).clamp(16, 30),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00D4AA)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Badges overlay - positioned absolutely to prevent overflow
          ..._buildFixedBadges(width, height),
        ],
      ),
    );
  }

  List<Widget> _buildFixedBadges(double width, double height) {
    List<Widget> badges = [];

    // Calculate safe badge dimensions
    final double maxBadgeWidth = width * 0.35; // Max 35% of card width
    final double maxBadgeHeight = height * 0.15; // Max 15% of image height
    final double badgePadding = (width * 0.03).clamp(4, 8);

    // Discount badge (top-left) - Always show discount percentage
    if (product.isOnSale) {
      final discountText = width < 100
          ? '${product.calculatedDiscountPercentage.toInt()}%'
          : '${product.calculatedDiscountPercentage.toInt()}% OFF';

      badges.add(
        Positioned(
          top: badgePadding,
          left: badgePadding,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxBadgeWidth,
              maxHeight: maxBadgeHeight,
              minWidth: 25,
              minHeight: 14,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: (width * 0.02).clamp(3, 8),
              vertical: (width * 0.01).clamp(2, 4),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                discountText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: (width * 0.028).clamp(8, 11),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    }

    // Stock/Quantity badge (top-right) - Show stock status OR quantity
    if (!product.inStock) {
      badges.add(
        Positioned(
          top: badgePadding,
          right: badgePadding,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxBadgeWidth,
              maxHeight: maxBadgeHeight,
              minWidth: 25,
              minHeight: 14,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: (width * 0.02).clamp(3, 8),
              vertical: (width * 0.01).clamp(2, 4),
            ),
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                width < 100 ? 'OOS' : 'Out of Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: (width * 0.025).clamp(7, 11),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    } else if (product.formattedQuantity.isNotEmpty) {
      // Show quantity/ml information
      badges.add(
        Positioned(
          top: badgePadding,
          right: badgePadding,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxBadgeWidth,
              maxHeight: maxBadgeHeight,
              minWidth: 25,
              minHeight: 14,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: (width * 0.02).clamp(3, 8),
              vertical: (width * 0.01).clamp(2, 4),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _formatQuantityForBadge(product.formattedQuantity, width),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: (width * 0.025).clamp(7, 11),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    }

    return badges;
  }

  String _formatQuantityForBadge(String quantity, double width) {
    // For very small cards, show abbreviated versions
    if (width < 80) {
      // Extract just the number and unit for tiny cards
      final regex = RegExp(r'(\d+(?:\.\d+)?)\s*([a-zA-Z]+)');
      final match = regex.firstMatch(quantity);
      if (match != null) {
        final number = match.group(1);
        final unit = match.group(2);
        return '${number}${unit?.substring(0, 1) ?? ''}'; // e.g., "500m" for "500ml"
      }
      return quantity.length > 4 ? quantity.substring(0, 4) : quantity;
    } else if (width < 120) {
      // Medium cards - show up to 6 characters
      return quantity.length > 6 ? '${quantity.substring(0, 5)}..' : quantity;
    } else {
      // Larger cards - show full quantity or truncate at 10 characters
      return quantity.length > 10 ? '${quantity.substring(0, 8)}..' : quantity;
    }
  }

  String _truncateQuantity(String quantity, double width) {
    return _formatQuantityForBadge(quantity, width);
  }

  Widget _buildContentContainer(double width, double height) {
    final double padding = (width * 0.04).clamp(6, 12);
    final double contentWidth = width - (padding * 2);
    final double contentHeight = height - (padding * 2);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name section - 35% of content height
          SizedBox(
            width: contentWidth,
            height: contentHeight * 0.35,
            child: _buildProductName(contentWidth, contentHeight * 0.35),
          ),

          // Quantity info section - 15% of content height (if available and space allows)
          if (product.formattedQuantity.isNotEmpty &&
              height > 70 &&
              width >= 140)
            SizedBox(
              width: contentWidth,
              height: contentHeight * 0.15,
              child: _buildQuantityInfo(contentWidth, contentHeight * 0.15),
            ),

          // Rating section - 15% of content height (only if space allows)
          if (height > 60)
            SizedBox(
              width: contentWidth,
              height: contentHeight * 0.15,
              child: _buildRating(contentWidth, contentHeight * 0.15),
            ),

          // Price section - remaining height (35% or 50% if no quantity/rating)
          Expanded(
            child: _buildPriceSection(contentWidth, null),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInfo(double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (width * 0.03).clamp(4, 8),
          vertical: (height * 0.2).clamp(1, 3),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            product.formattedQuantity,
            style: TextStyle(
              fontSize: (width * 0.06).clamp(8, 12),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF667EEA),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildProductName(double width, double height) {
    // Create title with quantity in parentheses if available
    String displayTitle = product.name;
    if (product.formattedQuantity.isNotEmpty) {
      displayTitle = '${product.name} (${product.formattedQuantity})';
    }

    return Container(
      width: width,
      height: height,
      child: Center(
        child: Text(
          displayTitle,
          style: TextStyle(
            fontSize: (width * 0.08).clamp(10, 16),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A365D),
            height: 1.1,
          ),
          maxLines: height > 25 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildRating(double width, double height) {
    final double starSize = (width * 0.06).clamp(10, 16);

    return Container(
      width: width,
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Stars
          SizedBox(
            width: starSize * 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                return Icon(
                  index < product.rating.floor()
                      ? Icons.star
                      : index < product.rating
                          ? Icons.star_half
                          : Icons.star_border,
                  color: Colors.amber,
                  size: starSize,
                );
              }),
            ),
          ),

          // Review count (if space allows)
          if (width > starSize * 5 + 20)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                child: Text(
                  '(${product.reviewCount})',
                  style: TextStyle(
                    fontSize: (width * 0.05).clamp(8, 12),
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double width, double? height) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualHeight = height ?? constraints.maxHeight;

        return Container(
          width: width,
          height: actualHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price info - 75% of width
              SizedBox(
                width: width * 0.75,
                height: actualHeight,
                child: _buildPriceInfo(width * 0.75, actualHeight),
              ),

              // Cart button - 25% of width
              SizedBox(
                width: width * 0.25,
                height: actualHeight,
                child: _buildCartButton(width * 0.25, actualHeight),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceInfo(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Original price and savings (if on sale and space allows)
          if (product.isOnSale && height > 30)
            Container(
              width: width,
              height: height * 0.3,
              child: Row(
                children: [
                  // Original price
                  Container(
                    constraints: BoxConstraints(maxWidth: width * 0.6),
                    child: Text(
                      '₹${product.originalPrice!.toInt()}',
                      style: TextStyle(
                        fontSize: (width * 0.08).clamp(8, 12),
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                    ),
                  ),

                  // Savings (if space allows)
                  if (width > 100)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Save ₹${product.savingsAmount.toInt()}',
                          style: TextStyle(
                            fontSize: (width * 0.06).clamp(6, 10),
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Current price
          Container(
            width: width,
            height:
                product.isOnSale && height > 30 ? height * 0.5 : height * 0.7,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₹${product.price.toInt()}',
                style: TextStyle(
                  fontSize: (width * 0.15).clamp(14, 24),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00D4AA),
                ),
              ),
            ),
          ),

          // Per unit price (if space allows)
          if (product.quantity != null &&
              product.quantity! > 0 &&
              width > 100 &&
              height > 45)
            Container(
              width: width,
              height: height * 0.2,
              child: Text(
                '₹${(product.price / product.quantity!).toStringAsFixed(1)}/${product.unit ?? 'unit'}',
                style: TextStyle(
                  fontSize: (width * 0.06).clamp(6, 10),
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartButton(double width, double height) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = cartProvider.isInCart(product.id);
        final double buttonSize = (height * 0.6).clamp(20, width * 0.8);

        return Container(
          width: width,
          height: height,
          child: Center(
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: product.inStock
                      ? [const Color(0xFF00D4AA), const Color(0xFF4FD1C7)]
                      : [Colors.grey.shade400, Colors.grey.shade500],
                ),
                borderRadius: BorderRadius.circular(buttonSize * 0.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(buttonSize * 0.2),
                  onTap: product.inStock
                      ? () {
                          cartProvider.addItem(
                            product.id,
                            product.name,
                            product.price,
                            product.imageUrl,
                            originalPrice: product.originalPrice,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              backgroundColor: const Color(0xFF00D4AA),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: Center(
                    child: Icon(
                      isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                      color: Colors.white,
                      size: buttonSize * 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getUnitTypeIcon(ProductUnitType unitType) {
    switch (unitType) {
      case ProductUnitType.liquid:
        return Icons.local_drink;
      case ProductUnitType.weight:
        return Icons.monitor_weight;
      case ProductUnitType.medicine:
        return Icons.medication;
      case ProductUnitType.pieces:
        return Icons.inventory_2;
      case ProductUnitType.other:
        return Icons.category;
    }
  }
}
