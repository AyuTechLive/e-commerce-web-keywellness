// Fixed checkout_screen.dart - Order only after payment success
import 'package:flutter/material.dart';
import 'package:keiwaywellness/service/payment_service.dart';
import 'package:keiwaywellness/service/shiprocket_service.dart';
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

  // Customer details controllers
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Address controllers
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  bool _isProcessing = false;
  bool _useProfileData = true;
  Map<String, dynamic>? _serviceabilityInfo;
  bool _isCheckingServiceability = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _printDebugInfo();
  }

  void _printDebugInfo() {
    final paymentService = PaymentService();
    paymentService.printEnvironmentInfo();
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
                  'Testing PhonePe & Delhivery connection...\nThis may take a few seconds.'),
            ),
          ],
        ),
      ),
    );

    try {
      final paymentService = PaymentService();
      final success = await paymentService.testPhonePeConnection();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ PhonePe & Delhivery ready!\nPayment and shipping services are working properly.'
                : '❌ Connection failed.\nCheck console for details or ensure you are logged in.',
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
      Navigator.pop(context);

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

  Future<void> _checkServiceability() async {
    final pincode = _pinCodeController.text.trim();
    if (pincode.length != 6) return;

    setState(() {
      _isCheckingServiceability = true;
      _serviceabilityInfo = null;
    });

    try {
      final serviceability =
          await DelhiveryService.checkServiceability(pincode);

      setState(() {
        _serviceabilityInfo = serviceability;
        _isCheckingServiceability = false;
      });

      if (serviceability != null && serviceability['serviceable']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Pincode $pincode is serviceable by Delhivery!\n'
              '${serviceability['city']}, ${serviceability['state']}\n'
              'COD: ${serviceability['cod_available'] ? 'Available' : 'Not Available'}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Pincode $pincode is not serviceable by Delhivery.\n'
              'Please try a different pincode.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingServiceability = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error checking serviceability: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check serviceability before placing order
    if (_serviceabilityInfo == null || !_serviceabilityInfo!['serviceable']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '❌ Please check pincode serviceability before placing order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('💳 Starting PAYMENT-FIRST order flow...');

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        throw Exception('User not authenticated. Please login first.');
      }

      // Calculate totals
      final subtotal = cartProvider.totalAmount;
      final shipping = subtotal > 500 ? 0.0 : 0.0;
      final total = subtotal + shipping;

      // Generate transaction ID
      final paymentService = PaymentService();
      final orderId = await paymentService.generateTransactionId();

      print('📋 Order Details:');
      print('   Order ID: $orderId');
      print('   Total: ₹$total');

      // Step 1: Initiate payment FIRST (don't save order yet)
      print('💳 Step 1: Initiating payment...');
      final paymentSuccess = await paymentService.initiatePayment(
        amount: total,
        orderId: orderId,
        userId: authProvider.user!.uid,
        userPhone: _phoneController.text.trim(),
      );

      if (!paymentSuccess) {
        throw Exception('Payment initiation failed. Please try again.');
      }

      print('✅ Payment initiated successfully');

      // Step 2: Save order details temporarily for payment verification
      print('💾 Step 2: Saving temporary order data...');

      final customerDetails = {
        'name': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final shippingAddress =
          '${_addressController.text}, ${_address2Controller.text.isNotEmpty ? '${_address2Controller.text}, ' : ''}${_cityController.text}, ${_stateController.text} - ${_pinCodeController.text}';

      // Save pending order data (for payment verification)
      await paymentService.savePendingOrderData(
        orderId: orderId,
        userId: authProvider.user!.uid,
        items: cartProvider.items,
        total: total,
        shippingAddress: shippingAddress,
        customerDetails: customerDetails,
      );

      // Step 3: Clear cart only after payment initiation success
      cartProvider.clearCart();

      // Step 4: Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '💳 Payment initiated!\nComplete payment to confirm your order.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to payment verification page
      context.go('/payment-verification/$orderId');
    } catch (e) {
      print('💥 Order placement failed: $e');

      String errorMessage = 'Order failed: ';
      if (e.toString().contains('unauthenticated')) {
        errorMessage += 'Please login and try again.';
      } else if (e.toString().contains('invalid-argument')) {
        errorMessage += 'Invalid details. Please check your information.';
      } else if (e.toString().contains('internal')) {
        errorMessage += 'Server error. Please try again later.';
      } else if (e.toString().contains('serviceable')) {
        errorMessage += 'Pincode not serviceable by Delhivery.';
      } else {
        errorMessage += 'Please check your connection and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
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
    if (authProvider.userModel != null && _useProfileData) {
      _nameController.text = authProvider.userModel!.name;
      _emailController.text = authProvider.userModel!.email;
      _phoneController.text = authProvider.userModel!.phone;

      // Try to parse existing address if available
      if (authProvider.userModel!.address.isNotEmpty) {
        final addressParts = authProvider.userModel!.address.split(',');
        if (addressParts.isNotEmpty) {
          _addressController.text = addressParts[0].trim();
          if (addressParts.length > 1) {
            _cityController.text = addressParts[addressParts.length - 2].trim();
          }
        }
      }
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCheckoutForm(),
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

  Widget _buildCheckoutForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checkout Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Payment-First Notice
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
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 10),
                        const Text(
                          'Secure Payment Process',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your order will be confirmed only after successful payment. No charges will be made if payment fails.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Customer Information Section
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
                        Icon(Icons.person, color: Colors.blue[600]),
                        const SizedBox(width: 10),
                        const Text(
                          'Customer Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Required for Delhivery shipping and order tracking',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Customer Name Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Email and Phone
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}')
                            .hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        helperText: 'For delivery updates',
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
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Shipping Address Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.green[600]),
                        const SizedBox(width: 10),
                        const Text(
                          'Shipping Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Order will be shipped via Delhivery logistics',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Address Line 1
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                  helperText: 'House/Flat number, Building name, Street',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  if (value.length < 10) {
                    return 'Please enter a complete address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Address Line 2
              TextFormField(
                controller: _address2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2 (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Landmark, Area name',
                ),
              ),
              const SizedBox(height: 15),

              // City, State, PIN Code
              Row(
                children: [
                  Expanded(
                    flex: 2,
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
                    flex: 2,
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
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _pinCodeController,
                      decoration: InputDecoration(
                        labelText: 'PIN Code *',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isCheckingServiceability
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _serviceabilityInfo != null
                                ? Icon(
                                    _serviceabilityInfo!['serviceable']
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _serviceabilityInfo!['serviceable']
                                        ? Colors.green
                                        : Colors.red,
                                  )
                                : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.length == 6) {
                          _checkServiceability();
                        } else {
                          setState(() {
                            _serviceabilityInfo = null;
                          });
                        }
                      },
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
                  ),
                ],
              ),

              // Serviceability Info
              if (_serviceabilityInfo != null) ...[
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _serviceabilityInfo!['serviceable']
                        ? Colors.green[50]
                        : Colors.red[50],
                    border: Border.all(
                      color: _serviceabilityInfo!['serviceable']
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
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
                                ? Colors.green[600]
                                : Colors.red[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _serviceabilityInfo!['serviceable']
                                ? 'Pincode Serviceable'
                                : 'Pincode Not Serviceable',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _serviceabilityInfo!['serviceable']
                                  ? Colors.green[600]
                                  : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                      if (_serviceabilityInfo!['serviceable']) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${_serviceabilityInfo!['city']}, ${_serviceabilityInfo!['state']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'COD: ${_serviceabilityInfo!['cod_available'] ? 'Available' : 'Not Available'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Prepaid: ${_serviceabilityInfo!['prepaid_available'] ? 'Available' : 'Not Available'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          'This pincode is not covered by Delhivery. Please try a different pincode.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Test Connection Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.wifi_protected_setup),
                  label: const Text('Test System Connection'),
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
    final shipping = subtotal > 500 ? 0.0 : 0.0;
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

            // Items List
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: cartProvider.items
                      .map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      const Icon(Icons.shopping_bag_outlined),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

            const Divider(height: 30),

            // Summary Calculations
            _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow(
              'Shipping',
              shipping == 0 ? 'Free' : '₹${shipping.toStringAsFixed(2)}',
              subtitle:
                  subtotal > 500 ? 'Free shipping on orders over ₹500' : null,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping,
                      color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ships via Delhivery',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
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
                onPressed: _isProcessing ||
                        (_serviceabilityInfo != null &&
                            !_serviceabilityInfo!['serviceable'])
                    ? null
                    : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                            'Initiating Payment...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pay ₹${total.toStringAsFixed(0)} with PhonePe',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Order confirmed only after payment success',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Payment first, then order confirmation. No charges if payment fails.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
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
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }
}
