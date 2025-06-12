// payment_verification_screen.dart - Modern UI with improved timing
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keiwaywellness/service/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PaymentVerificationScreen extends StatefulWidget {
  final String orderId;

  const PaymentVerificationScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _verificationTimer;
  Timer? _timeoutTimer;

  String _status =
      'verifying'; // verifying, success, failed, timeout, not_found
  String _message = 'Verifying your payment with PhonePe...';
  Map<String, dynamic>? _pendingOrderData;
  Map<String, dynamic>? _verificationResult;
  Map<String, dynamic>? _paymentData;

  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 20; // Increased retries for better coverage
  static const int _verificationTimeoutSeconds = 900; // 15 minutes instead of 5

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPendingOrderData();
    _startVerificationProcess();
    _startTimeoutTimer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _loadPendingOrderData() async {
    try {
      final data = await _paymentService.getPendingOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _pendingOrderData = data;
        });
      }
    } catch (e) {
      print('❌ Error loading pending order data: $e');
    }
  }

  void _startVerificationProcess() {
    print('🔍 Starting payment verification for order: ${widget.orderId}');

    // Start immediate verification
    _verifyPayment();

    // Set up periodic verification with progressive intervals
    _verificationTimer = Timer.periodic(
      Duration(seconds: _getVerificationInterval()),
      (timer) => _verifyPayment(),
    );
  }

  // Progressive verification intervals - start fast, then slower
  int _getVerificationInterval() {
    if (_retryCount < 5) return 3; // First 5 attempts: every 3 seconds
    if (_retryCount < 10) return 8; // Next 5 attempts: every 8 seconds
    return 15; // After that: every 15 seconds
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(
      const Duration(seconds: _verificationTimeoutSeconds),
      () {
        if (_status == 'verifying') {
          _handleVerificationTimeout();
        }
      },
    );
  }

  Future<void> _verifyPayment() async {
    if (_status != 'verifying' || _isRetrying) return;

    try {
      print('🔍 Payment verification attempt ${_retryCount + 1}...');

      final result =
          await _paymentService.verifyPaymentAndProcessOrder(widget.orderId);

      if (!mounted) return;

      _retryCount++;

      print('📥 Verification result: $result');

      final status = result['status'];
      final success = result['success'];

      if (success == true && status == 'completed') {
        _handlePaymentSuccess(result);
      } else if (status == 'pending') {
        _handlePaymentPending(result);
      } else if (status == 'failed') {
        _handlePaymentFailure(result);
      } else if (status == 'not_found') {
        _handleOrderNotFound(result);
      } else if (result['retry'] == true) {
        if (_retryCount >= _maxRetries) {
          _handleMaxRetriesReached();
        } else {
          _updateVerificationMessage(result);
        }
      } else {
        _handleUnexpectedResponse(result);
      }
    } catch (e) {
      print('❌ Payment verification error: $e');

      if (_retryCount >= _maxRetries) {
        _handleVerificationError(e.toString());
      } else {
        setState(() {
          _message =
              'Verification in progress...\nPlease wait while we confirm your payment.';
        });
      }
    }
  }

  void _handlePaymentSuccess(Map<String, dynamic> result) {
    print('✅ Payment verification successful!');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      setState(() {
        _status = 'success';
        _message = result['message'] ??
            'Payment successful! Your order has been confirmed and will be shipped.';
        _verificationResult = result;
        _paymentData = result['data'];
      });

      _animationController.reset();
      _animationController.forward();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '🎉 Payment verified! Order confirmed.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/order-success');
        }
      });
    }
  }

  void _handlePaymentPending(Map<String, dynamic> result) {
    print('⏳ Payment still pending');

    if (_retryCount >= _maxRetries) {
      _handleMaxRetriesReached();
    } else {
      setState(() {
        _message =
            'Payment verification in progress...\nThis may take a few minutes. Please wait.';
      });

      _verificationTimer?.cancel();
      _verificationTimer = Timer.periodic(
        Duration(seconds: _getVerificationInterval()),
        (timer) => _verifyPayment(),
      );
    }
  }

  void _handlePaymentFailure(Map<String, dynamic> result) {
    print('❌ Payment failed: ${result['error']}');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      setState(() {
        _status = 'failed';
        _message = result['message'] ?? 'Payment failed or was cancelled.';
        _verificationResult = result;
        _paymentData = result['data'];
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  void _handleOrderNotFound(Map<String, dynamic> result) {
    print('⚠️ Order not found - might be too early');

    if (_retryCount >= _maxRetries) {
      _handleMaxRetriesReached();
    } else {
      setState(() {
        _message =
            'Processing your payment...\nPlease wait while we verify with PhonePe.';
      });
    }
  }

  void _updateVerificationMessage(Map<String, dynamic> result) {
    setState(() {
      _message =
          'Verifying your payment...\nPlease wait while we confirm your transaction.';
    });
  }

  void _handleUnexpectedResponse(Map<String, dynamic> result) {
    print('⚠️ Unexpected response: $result');

    if (_retryCount >= _maxRetries) {
      _handleMaxRetriesReached();
    } else {
      setState(() {
        _message =
            'Processing payment verification...\nPlease wait while we check your payment status.';
      });
    }
  }

  void _handleMaxRetriesReached() {
    print('⚠️ Maximum verification retries reached');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      setState(() {
        _status = 'timeout';
        _message = 'Payment verification is taking longer than expected.\n'
            'If payment was successful, your order will be processed automatically.\n'
            'Please check your order history or contact support.';
      });
    }
  }

  void _handleVerificationTimeout() {
    print('⏰ Payment verification timeout after 15 minutes');

    _verificationTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      setState(() {
        _status = 'timeout';
        _message = 'Payment verification timed out after 15 minutes.\n'
            'If payment was successful on PhonePe, your order will be processed automatically.\n'
            'Please check your order history.';
      });
    }
  }

  void _handleVerificationError(String error) {
    print('💥 Payment verification error: $error');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      setState(() {
        _status = 'failed';
        _message = 'Verification failed due to system error.\n'
            'If payment was successful on PhonePe, please contact support.';
      });
    }
  }

  void _retryVerification() {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _status = 'verifying';
      _message = 'Retrying payment verification...';
      _retryCount = 0;
    });

    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
        _startVerificationProcess();
        _startTimeoutTimer();
      }
    });
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'success':
        return const Color(0xFF00D4AA);
      case 'failed':
        return Colors.red[600]!;
      case 'timeout':
        return Colors.orange[600]!;
      case 'not_found':
        return Colors.blue[600]!;
      default:
        return const Color(0xFF00D4AA);
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case 'success':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'timeout':
        return Icons.access_time;
      case 'not_found':
        return Icons.search;
      default:
        return Icons.payment;
    }
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'success':
        return 'Payment Verified!';
      case 'failed':
        return 'Payment Failed';
      case 'timeout':
        return 'Verification Timeout';
      case 'not_found':
        return 'Processing Payment';
      default:
        return 'Verifying Payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 768;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 40),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 600,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Status Icon with Animation
                          _buildStatusIcon(isMobile),
                          const SizedBox(height: 32),

                          // Status Title
                          Text(
                            _getStatusTitle(),
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.w900,
                              color: _getStatusColor(),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Status Message
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getStatusColor().withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _message,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: const Color(0xFF1A365D),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Order Details Card
                          if (_pendingOrderData != null) ...[
                            _buildOrderDetailsCard(isMobile),
                            const SizedBox(height: 24),
                          ],

                          // Payment Data Card (if available)
                          if (_paymentData != null && _status == 'success') ...[
                            _buildPaymentDataCard(isMobile),
                            const SizedBox(height: 24),
                          ],

                          // Action Buttons
                          _buildActionButtons(isMobile),

                          const SizedBox(height: 32),

                          // Information Section
                          _buildInfoSection(isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(bool isMobile) {
    return Container(
      width: isMobile ? 100 : 120,
      height: isMobile ? 100 : 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.1),
            _getStatusColor().withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: _getStatusColor(),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _status == 'verifying'
          ? ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                ),
              ),
            )
          : Icon(
              _getStatusIcon(),
              size: isMobile ? 50 : 60,
              color: _getStatusColor(),
            ),
    );
  }

  Widget _buildOrderDetailsCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
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
                  'Order Details',
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
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    _status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
                'Order ID', widget.orderId.substring(0, 12).toUpperCase()),
            _buildDetailRow('Amount',
                '₹${_pendingOrderData!['total']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildDetailRow('Items',
                '${(_pendingOrderData!['items'] as List?)?.length ?? 0} item(s)'),
            _buildDetailRow('Customer',
                '${_pendingOrderData!['customerDetails']?['name'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDataCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A365D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_paymentData!['orderId'] != null)
              _buildDetailRow(
                  'PhonePe Order ID', _paymentData!['orderId'].toString()),
            if (_paymentData!['state'] != null)
              _buildDetailRow(
                  'Payment State', _paymentData!['state'].toString()),
            if (_paymentData!['amount'] != null)
              _buildDetailRow(
                  'Amount (Paisa)', _paymentData!['amount'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    if (_status == 'verifying') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait while we verify your payment...',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_status == 'success') ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/order-success'),
              icon: const Icon(Icons.check_circle, size: 20),
              label: Text(
                'View Order Details',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _retryVerification,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                'Retry Verification',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home, size: 20),
            label: Text(
              'Back to Home',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.grey[700],
              padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (_status == 'failed' || _status == 'timeout') ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showSupportDialog(context),
              icon: const Icon(Icons.support_agent, size: 20),
              label: Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About Payment Verification',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A365D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getInfoMessage(),
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInfoMessage() {
    switch (_status) {
      case 'verifying':
        return 'We\'re using PhonePe\'s official API to verify your payment in real-time. This process may take up to 15 minutes for complete verification.';
      case 'success':
        return 'Your payment has been successfully verified. Your order has been confirmed and will be shipped via Delhivery.';
      case 'timeout':
        return 'Payment verification took longer than expected. If your payment was successful, it will be processed automatically within 24 hours.';
      case 'failed':
        return 'Payment verification indicates the payment was not successful. If you believe this is an error, please contact support immediately.';
      default:
        return 'Payment verification is in progress using PhonePe\'s official API for accurate payment status checking.';
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.blue[50]!,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A365D),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'For assistance with your payment verification:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildSupportItem(
                    Icons.email, 'Email', 'support@keiwaywellness.com'),
                _buildSupportItem(Icons.phone, 'Phone', '+91-XXXXXXXXXX'),
                _buildSupportItem(
                    Icons.schedule, 'Hours', '9 AM - 6 PM (Mon-Fri)'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Please include this information:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1A365D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Order ID: ${widget.orderId}',
                          style: const TextStyle(fontSize: 11)),
                      Text('Status: $_status',
                          style: const TextStyle(fontSize: 11)),
                      Text(
                          'Timestamp: ${DateTime.now().toString().substring(0, 19)}',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00D4AA),
                            width: 2,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00D4AA),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.copy,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Order ID: ${widget.orderId}'),
                                    ],
                                  ),
                                ),
                                backgroundColor: const Color(0xFF00D4AA),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: const Text(
                            'Copy Details',
                            style: TextStyle(
                              color: Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF1A365D),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A365D),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
