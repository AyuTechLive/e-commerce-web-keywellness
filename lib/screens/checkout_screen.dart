// checkout_screen.dart - Fixed and Optimized for Fast PhonePe Initiation
import 'package:flutter/material.dart';
import 'package:keiwaywellness/service/payment_service.dart';
import 'package:keiwaywellness/service/shiprocket_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/app_bar_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  bool _isProcessing = false;
  bool _useProfileData = true;
  Map<String, dynamic>? _serviceabilityInfo;
  bool _isCheckingServiceability = false;
  bool _showAddressForm = false;
  bool _setAsDefault = false;
  AddressModel? _selectedAddress;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _loadUserData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressNameController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
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
                'Checking services...',
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

      _showSnackBar(
        success ? '✅ Services ready!' : '❌ Connection issues detected',
        success ? Colors.green[600]! : Colors.red[600]!,
        action: !success
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _testConnection,
              )
            : null,
      );
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('❌ Test failed', Colors.red[600]!);
    }
  }

  Future<void> _checkServiceability(String pincode) async {
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
        _showSnackBar('✅ Delivery available for $pincode', Colors.green[600]!);
      } else {
        _showSnackBar(
            '❌ Delivery not available for $pincode', Colors.red[600]!);
      }
    } catch (e) {
      setState(() {
        _isCheckingServiceability = false;
      });
      _showSnackBar('❌ Error checking delivery', Colors.red[600]!);
    }
  }

  Future<void> _saveNewAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final newAddress = AddressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _addressNameController.text.trim(),
      addressLine1: _addressController.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      isDefault: _setAsDefault || authProvider.userModel!.addresses.isEmpty,
      createdAt: DateTime.now(),
    );

    final error = await authProvider.addAddress(newAddress);

    if (error == null) {
      setState(() {
        _selectedAddress = newAddress;
        _showAddressForm = false;
        _setAsDefault = false;
        _addressNameController.clear();
        _addressController.clear();
        _address2Controller.clear();
        _cityController.clear();
        _stateController.clear();
        _pinCodeController.clear();
        _serviceabilityInfo = null;
      });

      await _checkServiceability(newAddress.pinCode);
      _showSnackBar('✅ Address saved successfully!', Colors.green[600]!);
    } else {
      _showSnackBar('❌ Failed to save address: $error', Colors.red[600]!);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      _showSnackBar('❌ Please select a delivery address.', Colors.red[600]!);
      return;
    }

    if (_serviceabilityInfo == null || !_serviceabilityInfo!['serviceable']) {
      _showSnackBar(
          '❌ Delivery not available for selected address.', Colors.red[600]!);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        throw Exception('User not authenticated');
      }

      final subtotal = cartProvider.totalAmount;
      final shipping = subtotal > 500 ? 0.0 : 0.0;
      final total = subtotal + shipping;

      final paymentService = PaymentService();
      final orderId = await paymentService.generateTransactionId();

      // Initiate payment
      final paymentSuccess = await paymentService.initiatePayment(
        amount: total,
        orderId: orderId,
        userId: authProvider.user!.uid,
        userPhone: _phoneController.text.trim(),
      );

      if (!paymentSuccess) {
        throw Exception('Payment initiation failed');
      }

      // Save order data
      final customerDetails = {
        'name': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final shippingAddress = {
        'name': _selectedAddress!.name,
        'addressLine1': _selectedAddress!.addressLine1,
        'addressLine2': _selectedAddress!.addressLine2 ?? '',
        'city': _selectedAddress!.city,
        'state': _selectedAddress!.state,
        'pinCode': _selectedAddress!.pinCode,
        'phone': _phoneController.text.trim(),
        'country': 'India'
      };

      await paymentService.savePendingOrderData(
        orderId: orderId,
        userId: authProvider.user!.uid,
        items: cartProvider.items,
        total: total,
        shippingAddress: shippingAddress,
        customerDetails: customerDetails,
        originalTotal:
            cartProvider.hasDiscounts ? cartProvider.originalTotalAmount : null,
        totalSavings:
            cartProvider.hasDiscounts ? cartProvider.totalSavings : null,
        discountSummary: cartProvider.hasDiscounts
            ? {
                'hasDiscounts': true,
                'discountPercentage': cartProvider.cartDiscountPercentage,
                'discountedItems': cartProvider.discountedItems.length,
                'totalItems': cartProvider.items.length,
              }
            : null,
      );

      cartProvider.clearCart();

      _showSnackBar(
        '💳 Payment initiated!\nComplete payment to confirm your order.',
        Colors.blue[600]!,
        duration: const Duration(seconds: 3),
      );

      context.go('/payment-verification/$orderId');
    } catch (e) {
      String errorMessage = 'Order failed: ';
      if (e.toString().contains('unauthenticated')) {
        errorMessage += 'Please login and try again.';
      } else if (e.toString().contains('invalid-argument')) {
        errorMessage += 'Invalid details. Please check your information.';
      } else if (e.toString().contains('internal')) {
        errorMessage += 'Server error. Please try again later.';
      } else {
        errorMessage += 'Please check your connection and try again.';
      }

      _showSnackBar(
        '❌ $errorMessage',
        Colors.red[600]!,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _placeOrder,
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

      if (authProvider.userModel!.addresses.isNotEmpty) {
        _selectedAddress = authProvider.userModel!.defaultAddress ??
            authProvider.userModel!.addresses.first;

        if (_selectedAddress != null) {
          _checkServiceability(_selectedAddress!.pinCode);
        }
      }
    }
  }

  void _showSnackBar(
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
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
                        if (cartProvider.hasDiscounts) ...[
                          _buildDiscountBanner(cartProvider, isMobile),
                          const SizedBox(height: 24),
                        ],
                        if (isMobile)
                          Column(
                            children: [
                              _buildCheckoutForm(isMobile, authProvider),
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
                                child:
                                    _buildCheckoutForm(isMobile, authProvider),
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

  Widget _buildCheckoutForm(bool isMobile, AuthProvider authProvider) {
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

              _buildInfoCard(
                icon: Icons.person,
                iconColor: Colors.purple[600]!,
                title: 'Customer Information',
                description: 'Required for order tracking',
                backgroundColor: Colors.purple[50]!,
                borderColor: Colors.purple[200]!,
              ),

              const SizedBox(height: 24),

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

              _buildAddressSection(authProvider, isMobile),

              const SizedBox(height: 16),

              // Test Connection Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.wifi_tethering, size: 18),
                  label: const Text('Test Connection'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667EEA),
                    side: const BorderSide(color: Color(0xFF667EEA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection(AuthProvider authProvider, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          icon: Icons.local_shipping,
          iconColor: Colors.green[600]!,
          title: 'Shipping Address',
          description: 'Select or add delivery address',
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
        ),
        const SizedBox(height: 24),
        if (authProvider.userModel!.addresses.isNotEmpty) ...[
          Text(
            'Select Delivery Address',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 16),
          ...authProvider.userModel!.addresses
              .map((address) => _buildAddressCard(address, authProvider)),
          const SizedBox(height: 24),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF667EEA),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showAddressForm = !_showAddressForm;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _showAddressForm
                  ? const Color(0xFF667EEA)
                  : Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showAddressForm ? Icons.close : Icons.add_location_alt,
                  color:
                      _showAddressForm ? Colors.white : const Color(0xFF667EEA),
                ),
                const SizedBox(width: 8),
                Text(
                  _showAddressForm ? 'Cancel' : 'Add New Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _showAddressForm
                        ? Colors.white
                        : const Color(0xFF667EEA),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showAddressForm) ...[
          const SizedBox(height: 24),
          _buildNewAddressForm(isMobile),
        ],
      ],
    );
  }

  Widget _buildAddressCard(AddressModel address, AuthProvider authProvider) {
    final isSelected = _selectedAddress?.id == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF667EEA).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = address;
          });
          _checkServiceability(address.pinCode);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF667EEA)
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          address.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF667EEA)
                                : const Color(0xFF1A365D),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEFAULT',
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
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    itemBuilder: (context) => [
                      if (!address.isDefault)
                        PopupMenuItem(
                          value: 'default',
                          child: const Row(
                            children: [
                              Icon(Icons.star_outline, size: 16),
                              SizedBox(width: 8),
                              Text('Set as Default'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'default') {
                        await authProvider.setDefaultAddress(address.id);
                      } else if (value == 'delete') {
                        await authProvider.deleteAddress(address.id);
                        if (_selectedAddress?.id == address.id) {
                          setState(() {
                            _selectedAddress =
                                authProvider.userModel!.addresses.isNotEmpty
                                    ? authProvider.userModel!.addresses.first
                                    : null;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address.fullAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PIN: ${address.pinCode}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${address.city}, ${address.state}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewAddressForm(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 2),
      ),
      child: Form(
        key: _addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_location_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add New Address',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A365D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _addressNameController,
              label: 'Address Name (e.g., Home, Office) *',
              icon: Icons.label_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Address name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            _buildTextField(
              controller: _address2Controller,
              label: 'Address Line 2 (Optional)',
              icon: Icons.location_on_outlined,
              helperText: 'Landmark, Area name',
            ),
            const SizedBox(height: 16),
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
                        _checkServiceability(value);
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
            if (_serviceabilityInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _serviceabilityInfo!['serviceable']
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _serviceabilityInfo!['serviceable']
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _serviceabilityInfo!['serviceable']
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _serviceabilityInfo!['serviceable']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _serviceabilityInfo!['serviceable']
                          ? 'Delivery Available'
                          : 'Delivery Not Available',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _serviceabilityInfo!['serviceable']
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _setAsDefault,
              onChanged: (value) {
                setState(() {
                  _setAsDefault = value ?? false;
                });
              },
              title: const Text(
                'Set as default address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Use this address as default for future orders',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF667EEA),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveNewAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
            if (cartProvider.hasDiscounts) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[50]!, Colors.green[100]!],
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
            _buildSummaryRow(
              'Total Amount',
              '₹${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
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
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _isProcessing || _selectedAddress == null
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isProcessing || _selectedAddress == null
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
                onPressed: _isProcessing || _selectedAddress == null
                    ? null
                    : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing || _selectedAddress == null
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
                                _selectedAddress == null
                                    ? 'Select Address to Continue'
                                    : 'Pay ₹${total.toStringAsFixed(0)} with PhonePe',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedAddress != null) ...[
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
                                  'Secure payment with PhonePe',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
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
                      'Secure payment • Order confirmed only after successful payment',
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
