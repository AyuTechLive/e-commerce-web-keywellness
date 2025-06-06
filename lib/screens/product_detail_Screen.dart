import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../widgets/app_bar_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? product;
  bool isLoading = true;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final loadedProduct = await productProvider.getProduct(widget.productId);
    setState(() {
      product = loadedProduct;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: const CustomAppBar(),
        body: const Center(
          child: Text('Product not found'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildProductImages(),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 1,
                child: _buildProductInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImages() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: product!.imageUrl,
            width: double.infinity,
            height: 400,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: 400,
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 50),
            ),
            errorWidget: (context, url, error) => Container(
              width: double.infinity,
              height: 400,
              color: Colors.grey[200],
              child: const Icon(Icons.error, size: 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product!.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < product!.rating.floor()
                    ? Icons.star
                    : index < product!.rating
                        ? Icons.star_half
                        : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
            const SizedBox(width: 10),
            Text(
              '${product!.rating} (${product!.reviewCount} reviews)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '₹${product!.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: product!.inStock ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                product!.inStock ? Icons.check_circle : Icons.cancel,
                color: product!.inStock ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(
                product!.inStock ? 'In Stock' : 'Out of Stock',
                style: TextStyle(
                  color: product!.inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product!.description,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 30),
        if (product!.tags.isNotEmpty) ...[
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product!.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.grey[200],
                    ))
                .toList(),
          ),
          const SizedBox(height: 30),
        ],
        Row(
          children: [
            const Text(
              'Quantity:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 15),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () {
                            setState(() {
                              quantity--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: product!.inStock ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: OutlinedButton(
                onPressed: product!.inStock ? _buyNow : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart successfully!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _buyNow() {
    _addToCart();
    context.go('/cart');
  }
}
