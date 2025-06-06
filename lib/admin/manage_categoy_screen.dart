import 'package:flutter/material.dart';
import 'package:keiwaywellness/models/product.dart';
import 'package:keiwaywellness/providers/admin_provider.dart';
import 'package:keiwaywellness/providers/product_provider.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';

import '../models/category.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Text(
                  'No categories found. Add some categories to get started.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      category.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(category.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showEditCategoryDialog(context, category),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showDeleteCategoryDialog(context, category),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    _showCategoryDialog(context, 'Add Category');
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    _showCategoryDialog(context, 'Edit Category', category: category);
  }

  void _showCategoryDialog(BuildContext context, String title,
      {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final imageUrlController =
        TextEditingController(text: category?.imageUrl ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Container(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter image URL';
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
                        if (formKey.currentState!.validate()) {
                          String? error;

                          if (category == null) {
                            error = await adminProvider.addCategory(
                              name: nameController.text.trim(),
                              imageUrl: imageUrlController.text.trim(),
                              description: descriptionController.text.trim(),
                            );
                          } else {
                            error = await adminProvider.updateCategory(
                              id: category.id,
                              name: nameController.text.trim(),
                              imageUrl: imageUrlController.text.trim(),
                              description: descriptionController.text.trim(),
                            );
                          }

                          if (error == null) {
                            Navigator.pop(context);
                            Provider.of<CategoryProvider>(context,
                                    listen: false)
                                .refreshCategories();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(category == null
                                    ? 'Category added!'
                                    : 'Category updated!'),
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
                    : Text(category == null ? 'Add' : 'Update'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
                            await adminProvider.deleteCategory(category.id);

                        if (error == null) {
                          Navigator.pop(context);
                          Provider.of<CategoryProvider>(context, listen: false)
                              .refreshCategories();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Category deleted!'),
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

// admin/manage_products_screen.dart

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.products.isEmpty) {
            return const Center(
              child:
                  Text('No products found. Add some products to get started.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productProvider.products.length,
            itemBuilder: (context, index) {
              final product = productProvider.products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${product.price.toStringAsFixed(2)}'),
                      Text(
                        product.inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: product.inStock ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showEditProductDialog(context, product),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showDeleteProductDialog(context, product),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
    final imageUrlController =
        TextEditingController(text: product?.imageUrl ?? '');
    final tagsController =
        TextEditingController(text: product?.tags.join(', ') ?? '');
    final ratingController =
        TextEditingController(text: product?.rating.toString() ?? '4.0');
    final reviewCountController =
        TextEditingController(text: product?.reviewCount.toString() ?? '0');

    String? selectedCategoryId = product?.categoryId;
    bool inStock = product?.inStock ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Container(
            width: 500,
            height: 600,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter image URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        return DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
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
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                        hintText: 'vitamin, health, immunity',
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
                            final tags = tagsController.text
                                .split(',')
                                .map((tag) => tag.trim())
                                .where((tag) => tag.isNotEmpty)
                                .toList();

                            String? error;

                            if (product == null) {
                              error = await adminProvider.addProduct(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                price:
                                    double.parse(priceController.text.trim()),
                                imageUrl: imageUrlController.text.trim(),
                                categoryId: selectedCategoryId!,
                                inStock: inStock,
                                tags: tags,
                                rating: double.tryParse(
                                        ratingController.text.trim()) ??
                                    4.0,
                                reviewCount: int.tryParse(
                                        reviewCountController.text.trim()) ??
                                    0,
                              );
                            } else {
                              error = await adminProvider.updateProduct(
                                id: product.id,
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                price:
                                    double.parse(priceController.text.trim()),
                                imageUrl: imageUrlController.text.trim(),
                                categoryId: selectedCategoryId!,
                                inStock: inStock,
                                tags: tags,
                                rating: double.tryParse(
                                        ratingController.text.trim()) ??
                                    product.rating,
                                reviewCount: int.tryParse(
                                        reviewCountController.text.trim()) ??
                                    product.reviewCount,
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

  void _showDeleteProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
