import 'package:flutter/material.dart';
import 'package:keiwaywellness/models/product.dart';
import 'package:keiwaywellness/providers/admin_provider.dart';
import 'package:keiwaywellness/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/category_provider.dart';
import '../models/category.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  String _filterBy = 'all';
  ProductSortOption _sortBy = ProductSortOption.newest;
  List<String> _selectedCategories = [];
  final ImagePicker _picker = ImagePicker();

  // Image Upload Helper Method
  Future<String?> _uploadImage(XFile imageFile, String folder) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('admin_content')
          .child(folder)
          .child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        final Uint8List imageData = await imageFile.readAsBytes();
        uploadTask = storageRef.putData(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final File file = File(imageFile.path);
        uploadTask = storageRef.putFile(file);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick and Upload Image with proper loading states
  Future<String?> _pickAndUploadImage(
      String folder, BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading image...'),
              ],
            ),
          ),
        );

        final String? downloadUrl = await _uploadImage(image, folder);
        Navigator.pop(context); // Close loading dialog

        if (downloadUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          return downloadUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog if open
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.tune),
            tooltip: 'Advanced Filters',
          ),
          PopupMenuButton<String>(
            initialValue: _filterBy,
            onSelected: (value) {
              setState(() {
                _filterBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2),
                    SizedBox(width: 8),
                    Text('All Products'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'discounted',
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.red),
                    SizedBox(width: 8),
                    Text('On Sale'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'regular',
                child: Row(
                  children: [
                    Icon(Icons.label),
                    SizedBox(width: 8),
                    Text('Regular Price'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'out_of_stock',
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Out of Stock'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Consumer3<ProductProvider, CategoryProvider, AdminProvider>(
        builder:
            (context, productProvider, categoryProvider, adminProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Product> filteredProducts = _getFilteredProducts(
              productProvider.products, categoryProvider.categories);

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getFilterIcon(),
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessage(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  if (_selectedCategories.isNotEmpty || _filterBy != 'all') ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterBy = 'all';
                          _selectedCategories.clear();
                          _sortBy = ProductSortOption.newest;
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter and Sort Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Showing ${filteredProducts.length} products',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DropdownButton<ProductSortOption>(
                          value: _sortBy,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                            }
                          },
                          items: ProductSortOption.values.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(option.label),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (_selectedCategories.isNotEmpty ||
                        _filterBy != 'all') ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (_filterBy != 'all')
                            Chip(
                              label: Text(_getFilterLabel()),
                              backgroundColor: Colors.blue[100],
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _filterBy = 'all';
                                });
                              },
                            ),
                          ..._selectedCategories.map((categoryId) {
                            final category = categoryProvider.categories
                                .firstWhere((c) => c.id == categoryId);
                            return Chip(
                              label: Text(category.name),
                              backgroundColor: Colors.green[100],
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategories.remove(categoryId);
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];

                    // Get category name for display
                    final primaryCategory =
                        categoryProvider.categories.firstWhere(
                      (cat) => cat.id == product.categoryId,
                      orElse: () => Category(
                        id: '',
                        name: 'Unknown Category',
                        imageUrl: '',
                        description: '',
                      ),
                    );

                    // Get additional categories
                    final additionalCategories = <Category>[];
                    for (final categoryId in product.categoryIds) {
                      try {
                        final category = categoryProvider.categories
                            .firstWhere((cat) => cat.id == categoryId);
                        additionalCategories.add(category);
                      } catch (e) {
                        // Category not found, skip it
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            if (product.isOnSale)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${product.calculatedDiscountPercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price Information
                            if (product.isOnSale) ...[
                              Row(
                                children: [
                                  Text(
                                    '₹${product.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Save ₹${product.savingsAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else
                              Text('₹${product.price.toStringAsFixed(2)}'),

                            const SizedBox(height: 4),

                            // Quantity Information
                            if (product.formattedQuantity.isNotEmpty)
                              Text(
                                'Package: ${product.formattedQuantity}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                            const SizedBox(height: 4),

                            // Category Information
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    primaryCategory.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ...additionalCategories
                                    .map(
                                      (category) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.purple[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Status Information
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: product.inStock
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  product.inStock ? 'In Stock' : 'Out of Stock',
                                  style: TextStyle(
                                    color: product.inStock
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (product.isOnSale) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SALE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                // Rating
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      product.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      ' (${product.reviewCount})',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditProductDialog(context, product);
                                break;
                              case 'duplicate':
                                _showDuplicateProductDialog(context, product);
                                break;
                              case 'discount':
                                if (!product.isOnSale) {
                                  _showQuickDiscountDialog(context, product);
                                }
                                break;
                              case 'categories':
                                _showManageCategoriesDialog(context, product);
                                break;
                              case 'delete':
                                _showDeleteProductDialog(context, product);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit Product'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Duplicate Product'),
                                ],
                              ),
                            ),
                            if (!product.isOnSale)
                              const PopupMenuItem(
                                value: 'discount',
                                child: Row(
                                  children: [
                                    Icon(Icons.local_offer,
                                        color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Add Discount'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'categories',
                              child: Row(
                                children: [
                                  Icon(Icons.category, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Text('Manage Categories'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Product'),
                                ],
                              ),
                            ),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Product> _getFilteredProducts(
      List<Product> products, List<Category> categories) {
    List<Product> filtered = List.from(products);

    // Apply basic filter
    switch (_filterBy) {
      case 'discounted':
        filtered = filtered.where((product) => product.isOnSale).toList();
        break;
      case 'regular':
        filtered = filtered.where((product) => !product.isOnSale).toList();
        break;
      case 'out_of_stock':
        filtered = filtered.where((product) => !product.inStock).toList();
        break;
      default:
        break;
    }

    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((product) => _selectedCategories
              .any((categoryId) => product.belongsToCategory(categoryId)))
          .toList();
    }

    // Apply sorting
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    filtered = productProvider.sortProducts(filtered, _sortBy);

    return filtered;
  }

  IconData _getFilterIcon() {
    switch (_filterBy) {
      case 'discounted':
        return Icons.local_offer_outlined;
      case 'regular':
        return Icons.label_outlined;
      case 'out_of_stock':
        return Icons.inventory_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String _getEmptyMessage() {
    if (_selectedCategories.isNotEmpty) {
      return 'No products found in the selected categories';
    }

    switch (_filterBy) {
      case 'discounted':
        return 'No discounted products found';
      case 'regular':
        return 'No regular price products found';
      case 'out_of_stock':
        return 'No out of stock products found';
      default:
        return 'No products found. Add some products to get started.';
    }
  }

  String _getFilterLabel() {
    switch (_filterBy) {
      case 'discounted':
        return 'On Sale';
      case 'regular':
        return 'Regular Price';
      case 'out_of_stock':
        return 'Out of Stock';
      default:
        return 'All Products';
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Advanced Filters'),
            content: Container(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (categoryProvider.categories.isEmpty)
                      const Text('No categories available')
                    else
                      ...categoryProvider.categories.map((category) {
                        return CheckboxListTile(
                          title: Text(category.name),
                          subtitle: Text(category.description),
                          value: _selectedCategories.contains(category.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedCategories.add(category.id);
                              } else {
                                _selectedCategories.remove(category.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    const SizedBox(height: 16),
                    const Text(
                      'Sort Options',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ProductSortOption.values.map((option) {
                      return RadioListTile<ProductSortOption>(
                        title: Text(option.label),
                        value: option,
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategories.clear();
                    _sortBy = ProductSortOption.newest;
                    _filterBy = 'all';
                  });
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  this.setState(() {}); // Refresh the main screen
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageCategoriesDialog(BuildContext context, Product product) {
    List<String> tempSelectedCategories = List.from(product.categoryIds);
    String tempPrimaryCategory = product.categoryId;

    showDialog(
      context: context,
      builder: (context) => Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Manage Categories for "${product.name}"'),
            content: Container(
              width: 400,
              height: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Primary Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempPrimaryCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: categoryProvider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tempPrimaryCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Additional Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (categoryProvider.categories.isEmpty)
                      const Text('No additional categories available')
                    else
                      ...categoryProvider.categories
                          .where(
                              (category) => category.id != tempPrimaryCategory)
                          .map((category) {
                        return CheckboxListTile(
                          title: Text(category.name),
                          subtitle: Text(
                            category.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: tempSelectedCategories.contains(category.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                tempSelectedCategories.add(category.id);
                              } else {
                                tempSelectedCategories.remove(category.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  return ElevatedButton(
                    onPressed: adminProvider.isLoading
                        ? null
                        : () async {
                            final error = await adminProvider.updateProduct(
                              id: product.id,
                              name: product.name,
                              description: product.description,
                              price: product.price,
                              originalPrice: product.originalPrice,
                              imageUrl: product.imageUrl,
                              categoryId: tempPrimaryCategory,
                              additionalCategoryIds: tempSelectedCategories,
                              inStock: product.inStock,
                              tags: product.tags,
                              rating: product.rating,
                              reviewCount: product.reviewCount,
                              hasDiscount: product.hasDiscount,
                              discountPercentage: product.discountPercentage,
                              quantity: product.quantity,
                              unit: product.unit,
                              quantityDisplay: product.quantityDisplay,
                            );

                            if (error == null) {
                              Navigator.pop(context);
                              Provider.of<ProductProvider>(context,
                                      listen: false)
                                  .refreshProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product categories updated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $error')),
                              );
                            }
                          },
                    child: adminProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Update Categories'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDuplicateProductDialog(BuildContext context, Product product) {
    final nameController =
        TextEditingController(text: '${product.name} (Copy)');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Product'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This will create a copy of "${product.name}" with all its data.',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'New Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return ElevatedButton(
                onPressed: adminProvider.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final error = await adminProvider.addProduct(
                            name: nameController.text.trim(),
                            description: product.description,
                            price: product.price,
                            originalPrice: product.originalPrice,
                            imageUrl: product.imageUrl,
                            categoryId: product.categoryId,
                            additionalCategoryIds: product.categoryIds,
                            inStock: product.inStock,
                            tags: product.tags,
                            rating: product.rating,
                            reviewCount:
                                0, // Reset review count for duplicated product
                            hasDiscount: product.hasDiscount,
                            discountPercentage: product.discountPercentage,
                            quantity: product.quantity,
                            unit: product.unit,
                            quantityDisplay: product.quantityDisplay,
                          );

                          if (error == null) {
                            Navigator.pop(context);
                            Provider.of<ProductProvider>(context, listen: false)
                                .refreshProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Product duplicated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $error')),
                            );
                          }
                        }
                      },
                child: adminProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Duplicate'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showQuickDiscountDialog(BuildContext context, Product product) {
    final discountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Discount to ${product.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Price: ₹${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount percentage';
                  }
                  final discount = double.tryParse(value);
                  if (discount == null || discount <= 0 || discount >= 100) {
                    return 'Enter valid discount (1-99)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return ElevatedButton(
                onPressed: adminProvider.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final discountPercent =
                              double.parse(discountController.text);
                          final discountedPrice =
                              product.price * (1 - discountPercent / 100);

                          final error = await adminProvider.updateProduct(
                            id: product.id,
                            name: product.name,
                            description: product.description,
                            price: discountedPrice,
                            originalPrice: product.price,
                            imageUrl: product.imageUrl,
                            categoryId: product.categoryId,
                            additionalCategoryIds: product.categoryIds,
                            inStock: product.inStock,
                            tags: product.tags,
                            rating: product.rating,
                            reviewCount: product.reviewCount,
                            hasDiscount: true,
                            discountPercentage: discountPercent,
                            quantity: product.quantity,
                            unit: product.unit,
                            quantityDisplay: product.quantityDisplay,
                          );

                          if (error == null) {
                            Navigator.pop(context);
                            Provider.of<ProductProvider>(context, listen: false)
                                .refreshProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Discount applied! New price: ₹${discountedPrice.toStringAsFixed(2)}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $error')),
                            );
                          }
                        }
                      },
                child: adminProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Apply Discount'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductDialog(context, 'Add Product');
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    _showProductDialog(context, 'Edit Product', product: product);
  }

  void _showProductDialog(BuildContext context, String title,
      {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController =
        TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final originalPriceController = TextEditingController(
      text: product?.originalPrice?.toString() ?? '',
    );
    final imageUrlController =
        TextEditingController(text: product?.imageUrl ?? '');
    final tagsController =
        TextEditingController(text: product?.tags.join(', ') ?? '');
    final ratingController =
        TextEditingController(text: product?.rating.toString() ?? '4.0');
    final reviewCountController =
        TextEditingController(text: product?.reviewCount.toString() ?? '0');
    final quantityController =
        TextEditingController(text: product?.quantity?.toString() ?? '');
    final unitController = TextEditingController(text: product?.unit ?? '');

    String? selectedCategoryId = product?.categoryId;
    List<String> selectedAdditionalCategories =
        List.from(product?.categoryIds ?? []);
    bool inStock = product?.inStock ?? true;
    bool hasDiscount = product?.hasDiscount ?? false;
    String imageSource = 'url';
    String previewImageUrl = product?.imageUrl ?? '';
    XFile? pickedImage;
    Uint8List? webImage;
    File? imageFile;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Container(
            width: 700,
            height: 800,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Basic Information
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity and Unit Information
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              helperText: 'Package quantity (e.g., 500, 30, 1)',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final quantity = double.tryParse(value);
                                if (quantity == null || quantity <= 0) {
                                  return 'Enter valid quantity';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: unitController,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: const OutlineInputBorder(),
                              helperText: 'e.g., ml, gm, capsules, tablets',
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (value) {
                                  unitController.text = value;
                                },
                                itemBuilder: (context) => [
                                  'ml',
                                  'l',
                                  'gm',
                                  'g',
                                  'kg',
                                  'capsules',
                                  'tablets',
                                  'pieces',
                                  'nos',
                                  'units',
                                  'bottle',
                                  'pack',
                                  'box'
                                ]
                                    .map((unit) => PopupMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                              ),
                            ),
                            validator: (value) {
                              if (quantityController.text.isNotEmpty &&
                                  (value == null || value.isEmpty)) {
                                return 'Unit required when quantity is specified';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Discount Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            hasDiscount ? Colors.orange[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasDiscount
                              ? Colors.orange[200]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: hasDiscount ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasDiscount
                                  ? 'Product is on sale'
                                  : 'Regular price product',
                              style: TextStyle(
                                color: hasDiscount
                                    ? Colors.orange[800]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: hasDiscount,
                            onChanged: (value) {
                              setState(() {
                                hasDiscount = value;
                                if (!value) {
                                  originalPriceController.clear();
                                }
                              });
                            },
                            activeColor: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Fields
                    if (hasDiscount) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: originalPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Original Price (₹)',
                                border: OutlineInputBorder(),
                                helperText: 'Price before discount',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (hasDiscount &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter original price';
                                }
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter valid price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Sale Price (₹)',
                                border: OutlineInputBorder(),
                                helperText: 'Discounted price',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                final price = double.tryParse(value);
                                if (price == null) {
                                  return 'Please enter valid price';
                                }
                                if (hasDiscount &&
                                    originalPriceController.text.isNotEmpty) {
                                  final originalPrice = double.tryParse(
                                      originalPriceController.text);
                                  if (originalPrice != null &&
                                      price >= originalPrice) {
                                    return 'Sale price must be less than original price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Discount Calculation Display
                      if (priceController.text.isNotEmpty &&
                          originalPriceController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Builder(
                            builder: (context) {
                              final price =
                                  double.tryParse(priceController.text) ?? 0;
                              final originalPrice = double.tryParse(
                                      originalPriceController.text) ??
                                  0;
                              if (price > 0 &&
                                  originalPrice > 0 &&
                                  originalPrice > price) {
                                final discount =
                                    ((originalPrice - price) / originalPrice) *
                                        100;
                                final savings = originalPrice - price;
                                return Text(
                                  'Discount: ${discount.toStringAsFixed(1)}% | Savings: ₹${savings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: inStock,
                                  onChanged: (value) {
                                    setState(() {
                                      inStock = value ?? true;
                                    });
                                  },
                                ),
                                const Text('In Stock'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Image Source Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Image',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('URL'),
                                  value: 'url',
                                  groupValue: imageSource,
                                  onChanged: (value) {
                                    setState(() {
                                      imageSource = value!;
                                      pickedImage = null;
                                      webImage = null;
                                      imageFile = null;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Upload'),
                                  value: 'upload',
                                  groupValue: imageSource,
                                  onChanged: (value) {
                                    setState(() {
                                      imageSource = value!;
                                      previewImageUrl = '';
                                      imageUrlController.clear();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Input Section
                    if (imageSource == 'url') ...[
                      TextFormField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          setState(() {
                            previewImageUrl = value;
                          });
                        },
                        validator: (value) {
                          if (imageSource == 'url' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter image URL';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              pickedImage != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 48,
                              color: pickedImage != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pickedImage != null
                                  ? 'Image Selected'
                                  : 'Select Product Image',
                              style: TextStyle(
                                color: pickedImage != null
                                    ? Colors.green
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final url = await _pickAndUploadImage(
                                        'products',
                                        context,
                                        ImageSource.camera);
                                    if (url != null) {
                                      setState(() {
                                        imageUrlController.text = url;
                                        previewImageUrl = url;
                                        pickedImage = null;
                                        webImage = null;
                                        imageFile = null;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final url = await _pickAndUploadImage(
                                        'products',
                                        context,
                                        ImageSource.gallery);
                                    if (url != null) {
                                      setState(() {
                                        imageUrlController.text = url;
                                        previewImageUrl = url;
                                        pickedImage = null;
                                        webImage = null;
                                        imageFile = null;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImagePreview(
                            pickedImage, webImage, imageFile, previewImageUrl),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Primary Category
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        return DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Primary Category',
                            border: OutlineInputBorder(),
                          ),
                          items: categoryProvider.categories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                              // Remove from additional categories if selected as primary
                              selectedAdditionalCategories.remove(value);
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a primary category';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Additional Categories
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        final availableCategories = categoryProvider.categories
                            .where((cat) => cat.id != selectedCategoryId)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Categories (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (availableCategories.isEmpty)
                              const Text(
                                'No additional categories available',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 200),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children:
                                        availableCategories.map((category) {
                                      return CheckboxListTile(
                                        title: Text(category.name),
                                        subtitle: Text(
                                          category.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        value: selectedAdditionalCategories
                                            .contains(category.id),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedAdditionalCategories
                                                  .add(category.id);
                                            } else {
                                              selectedAdditionalCategories
                                                  .remove(category.id);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                        hintText: 'vitamin, health, immunity, sale',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ratingController,
                            decoration: const InputDecoration(
                              labelText: 'Rating (0-5)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final rating = double.tryParse(value);
                                if (rating == null ||
                                    rating < 0 ||
                                    rating > 5) {
                                  return 'Rating must be between 0 and 5';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: reviewCountController,
                            decoration: const InputDecoration(
                              labelText: 'Review Count',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (int.tryParse(value) == null) {
                                  return 'Please enter valid number';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                return ElevatedButton(
                  onPressed: adminProvider.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            // Validate image selection
                            if (imageSource == 'upload' &&
                                imageUrlController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select an image'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final tags = tagsController.text
                                .split(',')
                                .map((tag) => tag.trim())
                                .where((tag) => tag.isNotEmpty)
                                .toList();

                            final price =
                                double.parse(priceController.text.trim());
                            final originalPrice = hasDiscount &&
                                    originalPriceController.text.isNotEmpty
                                ? double.parse(
                                    originalPriceController.text.trim())
                                : null;

                            final quantity = quantityController.text.isNotEmpty
                                ? double.parse(quantityController.text.trim())
                                : null;
                            final unit = unitController.text.isNotEmpty
                                ? unitController.text.trim()
                                : null;

                            String? error;
                            String finalImageUrl =
                                imageUrlController.text.trim();

                            if (product == null) {
                              error = await adminProvider.addProduct(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                price: price,
                                originalPrice: originalPrice,
                                imageUrl: finalImageUrl,
                                categoryId: selectedCategoryId!,
                                additionalCategoryIds:
                                    selectedAdditionalCategories,
                                inStock: inStock,
                                tags: tags,
                                rating: double.tryParse(
                                        ratingController.text.trim()) ??
                                    4.0,
                                reviewCount: int.tryParse(
                                        reviewCountController.text.trim()) ??
                                    0,
                                hasDiscount: hasDiscount,
                                discountPercentage:
                                    hasDiscount && originalPrice != null
                                        ? ((originalPrice - price) /
                                                originalPrice) *
                                            100
                                        : null,
                                quantity: quantity,
                                unit: unit,
                              );
                            } else {
                              error = await adminProvider.updateProduct(
                                id: product.id,
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                price: price,
                                originalPrice: originalPrice,
                                imageUrl: finalImageUrl,
                                categoryId: selectedCategoryId!,
                                additionalCategoryIds:
                                    selectedAdditionalCategories,
                                inStock: inStock,
                                tags: tags,
                                rating: double.tryParse(
                                        ratingController.text.trim()) ??
                                    product.rating,
                                reviewCount: int.tryParse(
                                        reviewCountController.text.trim()) ??
                                    product.reviewCount,
                                hasDiscount: hasDiscount,
                                discountPercentage:
                                    hasDiscount && originalPrice != null
                                        ? ((originalPrice - price) /
                                                originalPrice) *
                                            100
                                        : null,
                                quantity: quantity,
                                unit: unit,
                              );
                            }

                            if (error == null) {
                              Navigator.pop(context);
                              Provider.of<ProductProvider>(context,
                                      listen: false)
                                  .refreshProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(product == null
                                      ? 'Product added!'
                                      : 'Product updated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $error')),
                              );
                            }
                          }
                        },
                  child: adminProvider.isLoading
                      ? const CircularProgressIndicator()
                      : Text(product == null ? 'Add' : 'Update'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile? pickedImage, Uint8List? webImage,
      File? imageFile, String imageUrl) {
    // Show picked image first
    if (pickedImage != null) {
      return kIsWeb && webImage != null
          ? Image.memory(
              webImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : imageFile != null
              ? Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      Text('Error loading image'),
                    ],
                  ),
                );
    }

    // Show URL image if available
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              Text('Error loading image'),
            ],
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    // Default placeholder
    return Container(
      color: Colors.grey[100],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, color: Colors.grey, size: 48),
          SizedBox(height: 8),
          Text(
            'Image Preview',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${product.name}"?'),
            if (product.isOnSale) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'This product is currently on sale',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (product.formattedQuantity.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Package: ${product.formattedQuantity}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return ElevatedButton(
                onPressed: adminProvider.isLoading
                    ? null
                    : () async {
                        final error =
                            await adminProvider.deleteProduct(product.id);

                        if (error == null) {
                          Navigator.pop(context);
                          Provider.of<ProductProvider>(context, listen: false)
                              .refreshProducts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product deleted!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: adminProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Delete',
                        style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
    );
  }
}
