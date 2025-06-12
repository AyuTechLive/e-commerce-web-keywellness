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
              child: Text(
                  'No categories found. Add some categories to get started.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];

              // Get products in this category
              final categoryProducts = productProvider.products
                  .where((product) => product.categoryId == category.id)
                  .toList();

              final saleProducts =
                  categoryProducts.where((product) => product.isOnSale).length;

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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${categoryProducts.length} products',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (saleProducts > 0) ...[
                            const SizedBox(width: 8),
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
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showEditCategoryDialog(context, category),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () => _showDeleteCategoryDialog(
                            context, category, categoryProducts.length),
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

// ManageProductsScreen with improved image upload mechanism
class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  String _filterBy = 'all';
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
            ],
            child: const Icon(Icons.filter_list),
          ),
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

          List<Product> filteredProducts = productProvider.products;
          switch (_filterBy) {
            case 'discounted':
              filteredProducts = productProvider.products
                  .where((product) => product.isOnSale)
                  .toList();
              break;
            case 'regular':
              filteredProducts = productProvider.products
                  .where((product) => !product.isOnSale)
                  .toList();
              break;
            default:
              filteredProducts = productProvider.products;
          }

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterBy == 'discounted'
                        ? Icons.local_offer_outlined
                        : Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterBy == 'discounted'
                        ? 'No discounted products found'
                        : _filterBy == 'regular'
                            ? 'No regular price products found'
                            : 'No products found. Add some products to get started.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filteredProducts.length} products',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_filterBy == 'discounted')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ON SALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
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
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!product.isOnSale)
                              IconButton(
                                onPressed: () =>
                                    _showQuickDiscountDialog(context, product),
                                icon: const Icon(Icons.local_offer,
                                    color: Colors.orange),
                                tooltip: 'Add Discount',
                              ),
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
                ),
              ),
            ],
          );
        },
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
                            inStock: product.inStock,
                            tags: product.tags,
                            rating: product.rating,
                            reviewCount: product.reviewCount,
                            hasDiscount: true,
                            discountPercentage: discountPercent,
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

    String? selectedCategoryId = product?.categoryId;
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
            width: 600,
            height: 800,
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
                  : const Text('Delete', style: TextStyle(color: Colors.white)),
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildImagePreview(
    XFile? pickedImage, Uint8List? webImage, File? imageFile, String imageUrl) {
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
