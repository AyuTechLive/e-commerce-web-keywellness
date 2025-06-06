import 'package:flutter/material.dart';
import 'package:keiwaywellness/service/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

import '../widgets/app_bar_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _printDebugInfo();
  }

  // Updated methods for your checkout screen - Replace the existing methods

  void _printDebugInfo() {
    // Create an instance to call the non-static method
    final paymentService = PaymentService();
    paymentService.printEnvironmentInfo();

    // Or use the static version for backward compatibility
    // PaymentService.printEnvironmentInfoStatic();
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                  'Testing PhonePe connection...\nThis may take a few seconds.'),
            ),
          ],
        ),
      ),
    );

    try {
      final paymentService = PaymentService();
      final success = await paymentService.testPhonePeConnection();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ PhonePe connection successful!\nFirebase Functions are working properly.'
                : '❌ PhonePe connection failed.\nCheck console for details or ensure you are logged in.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
          action: !success
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _testConnection,
                )
              : null,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Test failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _testConnection,
          ),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('🛒 Starting order placement...');

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is authenticated
      if (authProvider.user == null) {
        throw Exception('User not authenticated. Please login first.');
      }

      final shippingAddress =
          '${_addressController.text}, ${_cityController.text}, ${_stateController.text} - ${_pinCodeController.text}';

      final subtotal = cartProvider.totalAmount;
      final shipping = subtotal > 500 ? 0.0 : 50.0;
      final total = subtotal + shipping;

      // Generate transaction ID using Firebase Function
      final paymentService = PaymentService();
      final orderId = await paymentService.generateTransactionId();

      print('📋 Order Details:');
      print('   Order ID: $orderId');
      print('   Total: ₹$total');
      print('   Items: ${cartProvider.items.length}');
      print('   Phone: ${_phoneController.text}');
      print('   User ID: ${authProvider.user!.uid}');

      // Save order first
      await paymentService.saveOrder(
        userId: authProvider.user!.uid,
        items: cartProvider.items,
        total: total,
        shippingAddress: shippingAddress,
        paymentTransactionId: orderId,
      );

      print('✅ Order saved to database');

      // Initiate payment
      final success = await paymentService.initiatePayment(
        amount: total,
        orderId: orderId,
        userId: authProvider.user!.uid,
        userPhone: _phoneController.text.trim(),
      );

      if (success) {
        print('✅ Payment initiated successfully');

        // Clear cart
        cartProvider.clearCart();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Payment page opened! Complete your payment in the new tab/app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Navigate to success page
        context.go('/order-success');
      } else {
        print('❌ Payment initiation failed');
        throw Exception(
            'Payment initiation failed. Please try again or contact support.');
      }
    } catch (e) {
      print('💥 Order placement failed: $e');

      String errorMessage = 'Order failed: ';
      if (e.toString().contains('unauthenticated')) {
        errorMessage += 'Please login and try again.';
      } else if (e.toString().contains('invalid-argument')) {
        errorMessage +=
            'Invalid payment details. Please check your information.';
      } else if (e.toString().contains('internal')) {
        errorMessage += 'Server error. Please try again later.';
      } else {
        errorMessage += 'Please check your connection and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _placeOrder,
          ),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      _addressController.text = authProvider.userModel!.address;
      _phoneController.text = authProvider.userModel!.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer2<CartProvider, AuthProvider>(
        builder: (context, cartProvider, authProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildShippingForm(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: _buildOrderSummary(cartProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShippingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  helperText: 'Required for PhonePe payment',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // City and State
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // PIN Code
              TextFormField(
                controller: _pinCodeController,
                decoration: const InputDecoration(
                  labelText: 'PIN Code *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN code is required';
                  }
                  if (value.length != 6) {
                    return 'PIN code must be 6 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Payment Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.blue[600]),
                        const SizedBox(width: 10),
                        const Text(
                          'PhonePe Payment Gateway',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TEST MODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secure payment processing with PhonePe. This is a test environment - no real money will be charged.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Test Connection Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.wifi_protected_setup),
                  label: const Text('Test PhonePe Connection'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final subtotal = cartProvider.totalAmount;
    final shipping = subtotal > 500 ? 0.0 : 50.0;
    final total = subtotal + shipping;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Items
            ...cartProvider.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x ${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '₹${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                )),

            const Divider(),
            _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Shipping',
                shipping == 0 ? 'Free' : '₹${shipping.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow(
              'Total',
              '₹${total.toStringAsFixed(2)}',
              isTotal: true,
            ),

            const SizedBox(height: 30),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        'Pay ₹${total} with PhonePe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF2E7D32) : null,
            ),
          ),
        ],
      ),
    );
  }
}
