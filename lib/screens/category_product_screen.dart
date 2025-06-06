import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/product_card.dart';
import '../models/category.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;

  const CategoryProductsScreen({Key? key, required this.categoryId})
      : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  Category? category;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    final loadedCategory =
        await categoryProvider.getCategory(widget.categoryId);
    setState(() {
      category = loadedCategory;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : category == null
              ? const Center(child: Text('Category not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryHeader(),
                        const SizedBox(height: 30),
                        _buildProductsGrid(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category!.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (category!.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    category!.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products =
            productProvider.getProductsByCategory(widget.categoryId);

        if (products.isEmpty) {
          return const Center(
            child: Text(
              'No products found in this category',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products (${products.length})',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          ],
        );
      },
    );
  }
}
