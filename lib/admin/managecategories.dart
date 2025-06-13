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

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
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
        title: const Text('Manage Categories'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: Consumer2<CategoryProvider, ProductProvider>(
        builder: (context, categoryProvider, productProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No categories found. Add some categories to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];

              // Get products in this category (both primary and secondary assignments)
              final categoryProducts = productProvider.products
                  .where((product) => product.belongsToCategory(category.id))
                  .toList();

              final saleProducts =
                  categoryProducts.where((product) => product.isOnSale).length;

              // Get products where this is the primary category
              final primaryCategoryProducts = productProvider.products
                  .where((product) => product.categoryId == category.id)
                  .toList();

              // Get products where this is a secondary category
              final secondaryCategoryProducts = productProvider.products
                  .where((product) =>
                      product.categoryIds.contains(category.id) &&
                      product.categoryId != category.id)
                  .toList();

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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.description),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${categoryProducts.length} total products',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (primaryCategoryProducts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${primaryCategoryProducts.length} primary',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (secondaryCategoryProducts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${secondaryCategoryProducts.length} secondary',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (saleProducts > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$saleProducts on sale',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditCategoryDialog(context, category);
                              break;
                            case 'products':
                              _showCategoryProductsDialog(
                                  context, category, categoryProducts);
                              break;
                            case 'delete':
                              _showDeleteCategoryDialog(
                                  context, category, categoryProducts.length);
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
                                Text('Edit Category'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'products',
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2, color: Colors.green),
                                SizedBox(width: 8),
                                Text('View Products'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Category'),
                              ],
                            ),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
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

  void _showCategoryProductsDialog(
      BuildContext context, Category category, List<Product> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Products in "${category.name}"'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: products.isEmpty
              ? const Center(
                  child: Text('No products in this category'),
                )
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isPrimary = product.categoryId == category.id;

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          product.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Row(
                        children: [
                          Text('₹${product.price.toStringAsFixed(2)}'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPrimary
                                  ? Colors.green[100]
                                  : Colors.purple[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPrimary ? 'Primary' : 'Secondary',
                              style: TextStyle(
                                fontSize: 10,
                                color: isPrimary
                                    ? Colors.green[800]
                                    : Colors.purple[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: product.isOnSale
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
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
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

    String imageSource = 'url'; // 'url' or 'upload'
    String previewImageUrl = category?.imageUrl ?? '';
    XFile? pickedImage;
    Uint8List? webImage;
    File? imageFile;

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
                            'Image Source',
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
                                  : 'Select Image',
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
                                        'categories',
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
                                        'categories',
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

                            String? error;
                            String finalImageUrl =
                                imageUrlController.text.trim();

                            if (category == null) {
                              error = await adminProvider.addCategory(
                                name: nameController.text.trim(),
                                imageUrl: finalImageUrl,
                                description: descriptionController.text.trim(),
                              );
                            } else {
                              error = await adminProvider.updateCategory(
                                id: category.id,
                                name: nameController.text.trim(),
                                imageUrl: finalImageUrl,
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

  void _showDeleteCategoryDialog(
      BuildContext context, Category category, int productCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category.name}"?'),
            if (productCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This category contains $productCount products. Deleting it will affect these products.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 13,
                        ),
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
                            await adminProvider.deleteCategory(category.id);

                        if (error == null) {
                          Navigator.pop(context);
                          Provider.of<CategoryProvider>(context, listen: false)
                              .refreshCategories();
                          Provider.of<ProductProvider>(context, listen: false)
                              .refreshProducts();
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
