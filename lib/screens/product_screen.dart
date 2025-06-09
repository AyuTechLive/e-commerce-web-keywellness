// screens/all_products_screen.dart - Mobile Responsive Version
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

  String _sortBy = 'name'; // name, price_low, price_high, rating
  String? _selectedCategoryId;
  List<Product> _filteredProducts = [];
  bool _showFilters = false;
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
      appBar: const CustomAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildSearchAndFiltersSection(),
            if (_showFilters) _buildFiltersPanel(),
            Expanded(child: _buildProductsGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getScreenTitle(),
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Consumer<ProductProvider>(
                          builder: (context, productProvider, child) {
                            return Text(
                              '${_filteredProducts.length} products found',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: const Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                        ),
                      ],
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
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF00D4AA),
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts();
                            },
                            icon: const Icon(Icons.clear, size: 20),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) {
                    _filterProducts();
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Filter and Sort Controls
              Row(
                children: [
                  Expanded(
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
                        size: 18,
                      ),
                      label: const Text('Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showFilters
                            ? const Color(0xFF00D4AA)
                            : Colors.grey.shade100,
                        foregroundColor: _showFilters
                            ? Colors.white
                            : const Color(0xFF4A5568),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sort, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _getSortLabel(_sortBy),
                                style: const TextStyle(
                                  color: Color(0xFF4A5568),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                      ],
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
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 16),
              // Category Filter
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All Categories'),
                            selected: _selectedCategoryId == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _filterProducts();
                            },
                            selectedColor:
                                const Color(0xFF00D4AA).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF00D4AA),
                          ),
                          ...categoryProvider.categories.map(
                            (category) => FilterChip(
                              label: Text(category.name),
                              selected: _selectedCategoryId == category.id,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategoryId =
                                      selected ? category.id : null;
                                });
                                _filterProducts();
                              },
                              selectedColor:
                                  const Color(0xFF00D4AA).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF00D4AA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Price Range Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _priceRanges
                        .map((range) => FilterChip(
                              label: Text(range),
                              selected: _selectedPriceRange == range,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPriceRange = range;
                                });
                                _filterProducts();
                              },
                              selectedColor:
                                  const Color(0xFF00D4AA).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF00D4AA),
                            ))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Clear Filters Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedPriceRange = 'All Prices';
                      _searchController.clear();
                      _sortBy = 'name';
                    });
                    _filterProducts();
                  },
                  child: const Text('Clear All Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00D4AA),
                    side: const BorderSide(color: Color(0xFF00D4AA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading products...',
                      style: TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_filteredProducts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedPriceRange = 'All Prices';
                          _searchController.clear();
                          _sortBy = 'name';
                        });
                        _filterProducts();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                  crossAxisSpacing: isMobile ? 0 : 24,
                  mainAxisSpacing: isMobile ? 16 : 24,
                  childAspectRatio: isMobile ? 1.2 : 0.75,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductCard(product: product);
                },
              ),
            );
          },
        );
      },
    );
  }
}
