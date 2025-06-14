import 'package:flutter/material.dart';
import 'package:keiwaywellness/widgets/rivew_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:keiwaywellness/service/shiprocket_service.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/review_provider.dart';
import '../models/product.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  Product? product;
  List<Product> relatedProducts = [];
  bool isLoading = true;
  int quantity = 1;
  Map<String, dynamic>? _serviceabilityInfo;
  bool _isCheckingServiceability = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadProduct();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If productId changed, reload the product
    if (oldWidget.productId != widget.productId) {
      if (mounted) {
        setState(() {
          isLoading = true;
          product = null;
          relatedProducts = [];
          _serviceabilityInfo = null;
          quantity = 1;
          _pincodeController.clear();
        });
        _loadProduct();
      }
    }
  }

  Future<void> _loadProduct() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final loadedProduct = await productProvider.getProduct(widget.productId);

    if (loadedProduct != null) {
      // Load related products from the same category
      final allProducts = productProvider.products;
      final related = allProducts
          .where((p) =>
              p.categoryId == loadedProduct.categoryId &&
              p.id != loadedProduct.id)
          .take(6)
          .toList();

      if (mounted) {
        setState(() {
          product = loadedProduct;
          relatedProducts = related;
          isLoading = false;
        });
        _fadeController.forward();

        // Load reviews after product is loaded
        context.read<ReviewProvider>().loadProductReviews(widget.productId);
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkServiceability() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length != 6) return;

    if (mounted) {
      setState(() {
        _isCheckingServiceability = true;
        _serviceabilityInfo = null;
      });
    }

    try {
      final serviceability =
          await DelhiveryService.checkServiceability(pincode);

      if (mounted) {
        setState(() {
          _serviceabilityInfo = serviceability;
          _isCheckingServiceability = false;
        });
      }

      if (serviceability != null && serviceability['serviceable']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '✅ Pincode $pincode is serviceable by Delhivery!\n'
                        '${serviceability['city']}, ${serviceability['state']}\n'
                        'COD: ${serviceability['cod_available'] ? 'Available' : 'Not Available'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '❌ Pincode $pincode is not serviceable by Delhivery.\n'
                        'Please try a different pincode.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingServiceability = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error checking serviceability: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8BC34A)),
          ),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(),
        body: const Center(
          child: Text(
            'Product not found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 768;

            if (isMobile) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProductImage(),
                    _buildProductDetails(),

                    // Add Review Section for Mobile
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: ProductReviewSection(productId: widget.productId),
                    ),

                    if (relatedProducts.isNotEmpty) _buildRelatedProducts(),
                  ],
                ),
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Product Image
                          Expanded(
                            flex: 1,
                            child: _buildProductImage(),
                          ),
                          const SizedBox(width: 60),
                          // Right side - Product Details
                          Expanded(
                            flex: 1,
                            child: _buildProductDetails(),
                          ),
                        ],
                      ),
                    ),

                    // Add Review Section for Desktop (Full Width)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      child: ProductReviewSection(productId: widget.productId),
                    ),

                    // Related products below main content
                    if (relatedProducts.isNotEmpty) _buildRelatedProducts(),
                  ],
                ),
              );
            }
          },
        ),
      ),
      // Floating WhatsApp Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // WhatsApp functionality
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.chat,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Image.network(
            product!.imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 400,
                color: Colors.grey[50],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF8BC34A)),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 400,
              color: Colors.grey[50],
              child: const Icon(
                Icons.image_not_supported,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title with Green Arrow and Quantity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green Arrow Icon
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product!.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        height: 1.2,
                      ),
                    ),
                    // Show quantity and unit if available
                    if (product!.formattedQuantity.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          product!.formattedQuantity,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00D4AA),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Star Rating with Review Count
          Consumer<ReviewProvider>(
            builder: (context, reviewProvider, child) {
              final statistics =
                  reviewProvider.getProductReviewStatistics(widget.productId);
              final displayRating = statistics.totalReviews > 0
                  ? statistics.averageRating
                  : product!.rating;
              final displayCount = statistics.totalReviews > 0
                  ? statistics.totalReviews
                  : product!.reviewCount;

              return Row(
                children: [
                  ...List.generate(
                      5,
                      (index) => Icon(
                            Icons.star,
                            color: index < displayRating
                                ? const Color(0xFFFFB300)
                                : Colors.grey[300],
                            size: 18,
                          )),
                  const SizedBox(width: 8),
                  Text(
                    '${displayRating.toStringAsFixed(1)} ($displayCount reviews)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // MRP Section
          if (product!.isOnSale) ...[
            Row(
              children: [
                const Text(
                  'MRP: ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${product!.originalPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Price Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'PRICE: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '₹${product!.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 8),
              if (product!.quantity != null && product!.quantity! > 0)
                Text(
                  '(₹${(product!.price / product!.quantity!).toStringAsFixed(1)}/${product!.unit ?? 'unit'})',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Inclusive of All Taxes',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),

          const SizedBox(height: 16),

          // Savings Text
          if (product!.isOnSale)
            Text(
              "(You've saved ${product!.calculatedDiscountPercentage.toStringAsFixed(0)}% on this order)",
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 32),

          // Quantity Section
          const Text(
            'Quantity:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 12),

          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: quantity > 1
                      ? () {
                          if (mounted) {
                            setState(() => quantity--);
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: quantity > 1
                            ? const Color(0xFF333333)
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (mounted) {
                      setState(() => quantity++);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: product!.inStock ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF00D4AA),
                      width: 2,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: product!.inStock ? _buyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'BUY NOW',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Credits Section
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.orange[50],
          //     borderRadius: BorderRadius.circular(6),
          //     border: Border.all(color: Colors.orange[200]!),
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         width: 20,
          //         height: 20,
          //         decoration: const BoxDecoration(
          //           color: Colors.orange,
          //           shape: BoxShape.circle,
          //         ),
          //         child: const Icon(
          //           Icons.currency_rupee,
          //           color: Colors.white,
          //           size: 12,
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Text(
          //           'You will earn ₹${(product!.price * 0.07).toStringAsFixed(2)} credits on this purchase.',
          //           style: const TextStyle(
          //             fontSize: 14,
          //             color: Color(0xFF333333),
          //             fontWeight: FontWeight.w500,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

//const SizedBox(height: 24),

          // Delivery Check Section
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Check Estimate Delivery Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pincode Input Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Pincode..',
                      hintStyle: TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        _checkServiceability();
                      } else {
                        setState(() {
                          _serviceabilityInfo = null;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _checkServiceability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: _isCheckingServiceability
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CHECK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),

          // Serviceability Result
          if (_serviceabilityInfo != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _serviceabilityInfo!['serviceable']
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _serviceabilityInfo!['serviceable']
                      ? Colors.green[200]!
                      : Colors.red[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _serviceabilityInfo!['serviceable']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _serviceabilityInfo!['serviceable']
                            ? Colors.green
                            : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _serviceabilityInfo!['serviceable']
                            ? 'Delivery Available'
                            : 'Delivery Not Available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _serviceabilityInfo!['serviceable']
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  if (_serviceabilityInfo!['serviceable']) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Location: ${_serviceabilityInfo!['city']}, ${_serviceabilityInfo!['state']}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666)),
                    ),
                    Text(
                      'COD: ${_serviceabilityInfo!['cod_available'] ? 'Available' : 'Not Available'}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666)),
                    ),
                    const Text(
                      'Estimated delivery: 3-5 business days',
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Product Description
          _buildDescriptionSection(),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Text(
            product!.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF666666),
            ),
          ),
        ),

        // Tags if available
        if (product!.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product!.tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRelatedProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 768;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Related Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),

              // Different layouts for mobile vs desktop
              if (isMobile)
                // Mobile: Single column list view
                Column(
                  children: relatedProducts.take(4).map((relatedProduct) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          context.go('/product/${relatedProduct.id}');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                              // Product Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    relatedProduct.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      relatedProduct.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // Show quantity if available
                                    if (relatedProduct
                                        .formattedQuantity.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00D4AA)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          relatedProduct.formattedQuantity,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF00D4AA),
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 8),

                                    // Price
                                    Row(
                                      children: [
                                        if (relatedProduct.isOnSale) ...[
                                          Text(
                                            '₹${relatedProduct.originalPrice!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          '₹${relatedProduct.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00D4AA),
                                          ),
                                        ),
                                        if (relatedProduct.isOnSale) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${relatedProduct.calculatedDiscountPercentage.toStringAsFixed(0)}% OFF',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow Icon
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                // Desktop: Grid view
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount:
                      relatedProducts.length > 4 ? 4 : relatedProducts.length,
                  itemBuilder: (context, index) {
                    final relatedProduct = relatedProducts[index];
                    return GestureDetector(
                      onTap: () {
                        // Use pushReplacement to avoid stacking the same route
                        context
                            .pushReplacement('/product/${relatedProduct.id}');
                      },
                      child: ProductCard(product: relatedProduct),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    for (int i = 0; i < quantity; i++) {
      cartProvider.addItem(
        product!.id,
        product!.name,
        product!.price,
        product!.imageUrl,
        originalPrice: product!.originalPrice,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Added to cart successfully!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _buyNow() {
    _addToCart();
    context.go('/cart');
  }
}
