import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../models/category.dart';

class AllProductsScreen extends StatefulWidget {
  final String? categoryId;
  final String? searchQuery;

  const AllProductsScreen({
    Key? key,
    this.categoryId,
    this.searchQuery,
  }) : super(key: key);

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _sortBy = 'name'; // name, price_low, price_high, rating, discount
  String? _selectedCategoryId;
  List<Product> _filteredProducts = [];
  bool _showFilters = false;
  bool _showDiscountedOnly = false; // Add discount filter
  final List<String> _priceRanges = [
    'All Prices',
    'Under ₹500',
    '₹500 - ₹1,000',
    '₹1,000 - ₹2,000',
    'Above ₹2,000'
  ];
  String _selectedPriceRange = 'All Prices';

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
    _fadeController.forward();

    _selectedCategoryId = widget.categoryId;
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterProducts();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    List<Product> products = productProvider.products;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      products = productProvider.searchProducts(_searchController.text);
    }

    // Apply category filter
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      products = products
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    // Apply discount filter
    if (_showDiscountedOnly) {
      products = products.where((product) => product.isOnSale).toList();
    }

    // Apply price range filter
    if (_selectedPriceRange != 'All Prices') {
      products = products.where((product) {
        switch (_selectedPriceRange) {
          case 'Under ₹500':
            return product.price < 500;
          case '₹500 - ₹1,000':
            return product.price >= 500 && product.price <= 1000;
          case '₹1,000 - ₹2,000':
            return product.price >= 1000 && product.price <= 2000;
          case 'Above ₹2,000':
            return product.price > 2000;
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'discount':
        // Sort by discount percentage (highest first)
        products.sort((a, b) {
          final aDiscount = a.calculatedDiscountPercentage;
          final bDiscount = b.calculatedDiscountPercentage;
          return bDiscount.compareTo(aDiscount);
        });
        break;
      case 'name':
      default:
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(currentRoute: '/products'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Loading amazing products...',
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildScrollableContent();
          },
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return CustomScrollView(
          slivers: [
            // Search and Filters Section
            SliverToBoxAdapter(
              child: _buildSearchAndFiltersSection(),
            ),

            // Filters Panel (conditionally shown)
            if (_showFilters)
              SliverToBoxAdapter(
                child: _buildFiltersPanel(),
              ),

            // Products Content
            if (_filteredProducts.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(isMobile ? 20 : 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Results header
                      _buildResultsHeader(isMobile),
                      const SizedBox(height: 32),

                      // Products grid - Fixed for mobile
                      isMobile
                          ? _buildMobileProductsList()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isTablet ? 2 : 4,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio:
                                    0.64, // Adjusted for better proportions
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return ProductCard(product: product);
                              },
                            ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Separate mobile layout to prevent overflow
  Widget _buildMobileProductsList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 items per row
        crossAxisSpacing: 16, // Horizontal spacing between items
        mainAxisSpacing: 20, // Vertical spacing between items
        childAspectRatio:
            0.57, // Adjust this ratio based on your ProductCard dimensions
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductCard(product: product);
      },
    );
  }

  Widget _buildResultsHeader(bool isMobile) {
    final discountedCount = _filteredProducts.where((p) => p.isOnSale).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${_filteredProducts.length} Products',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Discover amazing products just for you',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (discountedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$discountedCount on sale',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _showDiscountedOnly
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _showDiscountedOnly ? '🔥 SALE ITEMS' : '🔥 TRENDING',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A365D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _showDiscountedOnly
                  ? 'No discounted products match your criteria'
                  : 'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _selectedPriceRange = 'All Prices';
                    _showDiscountedOnly = false;
                    _searchController.clear();
                    _sortBy = 'name';
                  });
                  _filterProducts();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScreenTitle() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return 'Search Results';
    } else if (_selectedCategoryId != null) {
      return 'Category Products';
    } else {
      return 'All Products';
    }
  }

  Widget _buildSearchAndFiltersSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterProducts();
                              },
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onChanged: (value) {
                    _filterProducts();
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Filter and Sort Controls
              isMobile
                  ? Column(
                      children: [
                        // Filter button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _showFilters
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF00D4AA),
                                        Color(0xFF4FD1C7)
                                      ],
                                    )
                                  : null,
                              color:
                                  _showFilters ? null : const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showFilters
                                    ? Colors.transparent
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showFilters = !_showFilters;
                                });
                              },
                              icon: Icon(
                                _showFilters
                                    ? Icons.filter_list_off
                                    : Icons.filter_list,
                                size: 20,
                              ),
                              label: const Text('Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: _showFilters
                                    ? Colors.white
                                    : const Color(0xFF4A5568),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Sort dropdown
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: PopupMenuButton<String>(
                              initialValue: _sortBy,
                              onSelected: (value) {
                                setState(() {
                                  _sortBy = value;
                                });
                                _filterProducts();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sort_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getSortLabel(_sortBy),
                                        style: const TextStyle(
                                          color: Color(0xFF4A5568),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down,
                                        size: 20),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'name',
                                  child: Text('Name (A-Z)'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_low',
                                  child: Text('Price (Low to High)'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_high',
                                  child: Text('Price (High to Low)'),
                                ),
                                const PopupMenuItem(
                                  value: 'rating',
                                  child: Text('Rating (High to Low)'),
                                ),
                                const PopupMenuItem(
                                  value: 'discount',
                                  child: Text('Discount (High to Low)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _showFilters
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF00D4AA),
                                        Color(0xFF4FD1C7)
                                      ],
                                    )
                                  : null,
                              color:
                                  _showFilters ? null : const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showFilters
                                    ? Colors.transparent
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showFilters = !_showFilters;
                                });
                              },
                              icon: Icon(
                                _showFilters
                                    ? Icons.filter_list_off
                                    : Icons.filter_list,
                                size: 20,
                              ),
                              label: const Text('Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: _showFilters
                                    ? Colors.white
                                    : const Color(0xFF4A5568),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: PopupMenuButton<String>(
                              initialValue: _sortBy,
                              onSelected: (value) {
                                setState(() {
                                  _sortBy = value;
                                });
                                _filterProducts();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sort_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _getSortLabel(_sortBy),
                                        style: const TextStyle(
                                          color: Color(0xFF4A5568),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down,
                                        size: 20),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'name',
                                  child: Text('Name (A-Z)'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_low',
                                  child: Text('Price (Low to High)'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_high',
                                  child: Text('Price (High to Low)'),
                                ),
                                const PopupMenuItem(
                                  value: 'rating',
                                  child: Text('Rating (High to Low)'),
                                ),
                                const PopupMenuItem(
                                  value: 'discount',
                                  child: Text('Discount (High to Low)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_low':
        return 'Price ↑';
      case 'price_high':
        return 'Price ↓';
      case 'rating':
        return 'Rating ↓';
      case 'discount':
        return 'Discount ↓';
      case 'name':
      default:
        return 'Name A-Z';
    }
  }

  Widget _buildFiltersPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Special Offers Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Special Offers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        'All Products',
                        !_showDiscountedOnly,
                        () {
                          setState(() {
                            _showDiscountedOnly = false;
                          });
                          _filterProducts();
                        },
                      ),
                      _buildFilterChip(
                        'On Sale Only 🔥',
                        _showDiscountedOnly,
                        () {
                          setState(() {
                            _showDiscountedOnly = true;
                          });
                          _filterProducts();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Filter
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            'All Categories',
                            _selectedCategoryId == null,
                            () {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _filterProducts();
                            },
                          ),
                          ...categoryProvider.categories.map(
                            (category) => _buildFilterChip(
                              category.name,
                              _selectedCategoryId == category.id,
                              () {
                                setState(() {
                                  _selectedCategoryId =
                                      _selectedCategoryId == category.id
                                          ? null
                                          : category.id;
                                });
                                _filterProducts();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Price Range Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _priceRanges
                        .map((range) => _buildFilterChip(
                              range,
                              _selectedPriceRange == range,
                              () {
                                setState(() {
                                  _selectedPriceRange = range;
                                });
                                _filterProducts();
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Clear Filters Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedPriceRange = 'All Prices';
                        _showDiscountedOnly = false;
                        _searchController.clear();
                        _sortBy = 'name';
                      });
                      _filterProducts();
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear All Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                )
              : null,
          color: selected ? null : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 16,
              ),
            if (selected) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF4A5568),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
