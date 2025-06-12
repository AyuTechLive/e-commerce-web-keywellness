// Modern checkout_screen.dart with consistent UI theme
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

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _loadUserData();
    _printDebugInfo();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  void _printDebugInfo() {
    final paymentService = PaymentService();
    paymentService.printEnvironmentInfo();
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Testing Connection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Checking PhonePe & Delhivery services...\nThis may take a few seconds.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final paymentService = PaymentService();
      final success = await paymentService.testPhonePeConnection();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: success ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? '✅ PhonePe & Delhivery ready!\nPayment and shipping services are working properly.'
                        : '❌ Connection failed.\nCheck console for details or ensure you are logged in.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: success ? Colors.green[600] : Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '❌ Test failed: ${e.toString()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
            content: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ Pincode $pincode is serviceable by Delhivery!\n'
                      '${serviceability['city']}, ${serviceability['state']}\n'
                      'COD: ${serviceability['cod_available'] ? 'Available' : 'Not Available'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cancel,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '❌ Pincode $pincode is not serviceable by Delhivery.\n'
                      'Please try a different pincode.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_off,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '❌ Please check pincode serviceability before placing order.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '💳 Payment initiated!\nComplete payment to confirm your order.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
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
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '❌ $errorMessage',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: const CustomAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer2<CartProvider, AuthProvider>(
          builder: (context, cartProvider, authProvider, child) {
            if (cartProvider.items.isEmpty) {
              return _buildEmptyCart();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 768;
                final bool isTablet =
                    constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      children: [
                        // Discount Banner (if applicable)
                        if (cartProvider.hasDiscounts) ...[
                          _buildDiscountBanner(cartProvider, isMobile),
                          const SizedBox(height: 24),
                        ],

                        if (isMobile)
                          Column(
                            children: [
                              _buildCheckoutForm(isMobile),
                              const SizedBox(height: 24),
                              _buildOrderSummary(cartProvider, isMobile),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isTablet ? 3 : 2,
                                child: _buildCheckoutForm(isMobile),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child:
                                    _buildOrderSummary(cartProvider, isMobile),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiscountBanner(CartProvider cartProvider, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎉 Amazing Savings!',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You saved ₹${cartProvider.totalSavings.toStringAsFixed(2)} (${cartProvider.cartDiscountPercentage.toStringAsFixed(0)}% off)',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${cartProvider.discountedItems.length} items on sale',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.1),
                          const Color(0xFF764BA2).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: isMobile ? 80 : 120,
                      color: const Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A365D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add some products to continue with checkout',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 32 : 48,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Continue Shopping',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutForm(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checkout Details',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 24),

              // Payment-First Notice

              // Customer Information Section
              _buildInfoCard(
                icon: Icons.person,
                iconColor: Colors.purple[600]!,
                title: 'Customer Information',
                description:
                    'Required for Delhivery shipping and order tracking',
                backgroundColor: Colors.purple[50]!,
                borderColor: Colors.purple[200]!,
              ),

              const SizedBox(height: 24),

              // Customer Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'First Name *',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email and Phone
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _emailController,
                      label: 'Email Address *',
                      icon: Icons.email_outlined,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number *',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      helperText: 'For delivery updates',
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

              const SizedBox(height: 32),

              // Shipping Address Section
              _buildInfoCard(
                icon: Icons.local_shipping,
                iconColor: Colors.green[600]!,
                title: 'Shipping Address',
                description: 'Order will be shipped via Delhivery logistics',
                backgroundColor: Colors.green[50]!,
                borderColor: Colors.green[200]!,
              ),

              const SizedBox(height: 24),

              // Address Line 1
              _buildTextField(
                controller: _addressController,
                label: 'Address Line 1 *',
                icon: Icons.home,
                maxLines: 2,
                helperText: 'House/Flat number, Building name, Street',
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
              const SizedBox(height: 16),

              // Address Line 2
              _buildTextField(
                controller: _address2Controller,
                label: 'Address Line 2 (Optional)',
                icon: Icons.location_on_outlined,
                helperText: 'Landmark, Area name',
              ),
              const SizedBox(height: 16),

              // City, State, PIN Code
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City *',
                      icon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State *',
                      icon: Icons.map,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      controller: _pinCodeController,
                      label: 'PIN Code *',
                      icon: Icons.pin_drop,
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
                      suffixIcon: _isCheckingServiceability
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF667EEA)),
                                ),
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
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _serviceabilityInfo!['serviceable']
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _serviceabilityInfo!['serviceable']
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _serviceabilityInfo!['serviceable']
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _serviceabilityInfo!['serviceable']
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _serviceabilityInfo!['serviceable']
                                ? 'Pincode Serviceable'
                                : 'Pincode Not Serviceable',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _serviceabilityInfo!['serviceable']
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      if (_serviceabilityInfo!['serviceable']) ...[
                        const SizedBox(height: 12),
                        _buildServiceabilityRow(
                          'Location',
                          '${_serviceabilityInfo!['city']}, ${_serviceabilityInfo!['state']}',
                        ),
                        _buildServiceabilityRow(
                          'COD',
                          _serviceabilityInfo!['cod_available']
                              ? 'Available'
                              : 'Not Available',
                        ),
                        _buildServiceabilityRow(
                          'Prepaid',
                          _serviceabilityInfo!['prepaid_available']
                              ? 'Available'
                              : 'Not Available',
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          'This pincode is not covered by Delhivery. Please try a different pincode.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Test Connection Button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A365D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helperText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.grey[600]),
        helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1A365D),
      ),
    );
  }

  Widget _buildServiceabilityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A365D),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider, bool isMobile) {
    final subtotal = cartProvider.totalAmount;
    final originalSubtotal = cartProvider.originalTotalAmount;
    final totalSavings = cartProvider.totalSavings;
    final shipping = subtotal > 500 ? 0.0 : 50.0;
    final total = subtotal + shipping;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A365D),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cartProvider.items.length} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Items List
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: cartProvider.items
                      .map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFBFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.hasDiscount
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                width: item.hasDiscount ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          width: 50,
                                          height: 50,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: Colors.grey,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                        // Discount Badge on Image
                                        if (item.hasDiscount)
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${item.discountPercentage.toStringAsFixed(0)}%',
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
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A365D),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // Quantity and Price Info
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF667EEA),
                                                  Color(0xFF764BA2)
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Qty: ${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (item.hasDiscount) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'SALE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      // Price Information
                                      if (item.hasDiscount) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${item.originalPrice!.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '₹${item.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Save ₹${item.savings.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          '₹${item.price.toStringAsFixed(2)} each',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Item Total
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00D4AA),
                                            Color(0xFF4FD1C7)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '₹${item.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (item.hasDiscount) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Saved ₹${item.savings.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),

            // Discount Summary (if applicable)
            if (cartProvider.hasDiscounts) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[50]!,
                      Colors.green[100]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Discount Applied',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cartProvider.cartDiscountPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Original Total',
                        '₹${originalSubtotal.toStringAsFixed(2)}'),
                    _buildSummaryRow(
                      'Total Savings',
                      '-₹${totalSavings.toStringAsFixed(2)}',
                      valueColor: const Color(0xFF4CAF50),
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'After Discount',
                      '₹${subtotal.toStringAsFixed(2)}',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Order Totals
            _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Shipping',
              shipping == 0 ? 'Free' : '₹${shipping.toStringAsFixed(2)}',
              subtitle: subtotal > 500
                  ? 'Free shipping on orders over ₹500'
                  : 'Add ₹${(500 - subtotal).toStringAsFixed(2)} for free shipping',
              currentSubtotal: subtotal,
            ),

            const SizedBox(height: 12),
            // Shipping Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ships via Delhivery',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A365D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 12),

            // Final Total
            _buildSummaryRow(
              'Total Amount',
              '₹${total.toStringAsFixed(2)}',
              isTotal: true,
            ),

            // Total Savings Highlight
            if (cartProvider.hasDiscounts) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.savings, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'You saved ₹${totalSavings.toStringAsFixed(2)} on this order!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Place Order Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _isProcessing ||
                        (_serviceabilityInfo != null &&
                            !_serviceabilityInfo!['serviceable'])
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isProcessing ||
                        (_serviceabilityInfo != null &&
                            !_serviceabilityInfo!['serviceable'])
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ||
                        (_serviceabilityInfo != null &&
                            !_serviceabilityInfo!['serviceable'])
                    ? null
                    : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing ||
                          (_serviceabilityInfo != null &&
                              !_serviceabilityInfo!['serviceable'])
                      ? Colors.grey[300]
                      : Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? Row(
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
                          const SizedBox(width: 12),
                          const Text(
                            'Initiating Payment...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.payment,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pay ₹${total.toStringAsFixed(0)} with PhonePe',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (cartProvider.hasDiscounts) ...[
                                Text(
                                  'Including ₹${totalSavings.toStringAsFixed(0)} savings • ',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                              const Text(
                                'Order confirmed only after payment success',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Secure payment • No charges if payment fails • Order confirmed only after successful payment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A365D),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isHighlighted = false,
    String? subtitle,
    Color? valueColor,
    double? currentSubtotal,
  }) {
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
                  fontWeight: isTotal || isHighlighted
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isTotal
                      ? const Color(0xFF1A365D)
                      : isHighlighted
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor ??
                      (isTotal
                          ? const Color(0xFF667EEA)
                          : isHighlighted
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1A365D)),
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: (currentSubtotal != null && currentSubtotal > 500)
                        ? Colors.green[600]
                        : Colors.orange[600],
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
