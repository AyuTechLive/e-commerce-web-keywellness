// payment_verification_screen.dart - Complete implementation with PhonePe Order Status API
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
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _verificationTimer;
  Timer? _timeoutTimer;

  String _status =
      'verifying'; // verifying, success, failed, timeout, not_found
  String _message = 'Verifying payment using PhonePe Order Status API...';
  Map<String, dynamic>? _pendingOrderData;
  Map<String, dynamic>? _verificationResult;
  Map<String, dynamic>? _paymentData;

  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 10; // Increased retries for better coverage
  static const int _verificationTimeoutSeconds = 300; // 5 minutes

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
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

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
    print(
        '🔍 Starting payment verification using PhonePe Order Status API for order: ${widget.orderId}');

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
    if (_retryCount < 3) return 2; // First 3 attempts: every 2 seconds
    if (_retryCount < 6) return 5; // Next 3 attempts: every 5 seconds
    return 10; // After that: every 10 seconds
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
      print(
          '🔍 PhonePe Order Status API verification attempt ${_retryCount + 1}...');

      final result =
          await _paymentService.verifyPaymentAndProcessOrder(widget.orderId);

      if (!mounted) return;

      _retryCount++;

      print('📥 PhonePe Order Status API result: $result');

      final status = result['status'];
      final success = result['success'];

      if (success == true && status == 'completed') {
        // Payment successful according to PhonePe Order Status API
        _handlePaymentSuccess(result);
      } else if (status == 'pending') {
        // Payment still pending according to PhonePe Order Status API
        _handlePaymentPending(result);
      } else if (status == 'failed') {
        // Payment failed according to PhonePe Order Status API
        _handlePaymentFailure(result);
      } else if (status == 'not_found') {
        // Order not found in PhonePe - might be too early
        _handleOrderNotFound(result);
      } else if (result['retry'] == true) {
        // Continue verification if retry is suggested
        if (_retryCount >= _maxRetries) {
          _handleMaxRetriesReached();
        } else {
          _updateVerificationMessage(result);
        }
      } else {
        // Unexpected response
        _handleUnexpectedResponse(result);
      }
    } catch (e) {
      print('❌ Payment verification error: $e');

      if (_retryCount >= _maxRetries) {
        _handleVerificationError(e.toString());
      } else {
        setState(() {
          _message =
              'Verification attempt $_retryCount failed, retrying...\nUsing PhonePe Order Status API\n${e.toString()}';
        });
      }
    }
  }

  void _handlePaymentSuccess(Map<String, dynamic> result) {
    print('✅ Payment verification successful via PhonePe Order Status API!');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();

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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Payment verified successful! Order confirmed.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Auto-navigate to success page after a delay
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/order-success');
        }
      });
    }
  }

  void _handlePaymentPending(Map<String, dynamic> result) {
    print('⏳ Payment still pending according to PhonePe Order Status API');

    if (_retryCount >= _maxRetries) {
      _handleMaxRetriesReached();
    } else {
      setState(() {
        _message = result['message'] ??
            'Payment verification in progress...\nAttempt $_retryCount of $_maxRetries\nUsing PhonePe Order Status API';
      });

      // Restart timer with new interval
      _verificationTimer?.cancel();
      _verificationTimer = Timer.periodic(
        Duration(seconds: _getVerificationInterval()),
        (timer) => _verifyPayment(),
      );
    }
  }

  void _handlePaymentFailure(Map<String, dynamic> result) {
    print(
        '❌ Payment failed according to PhonePe Order Status API: ${result['error']}');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();

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
    print(
        '⚠️ Order not found in PhonePe Order Status API - might be too early');

    if (_retryCount >= _maxRetries) {
      _handleMaxRetriesReached();
    } else {
      setState(() {
        _message =
            'Payment verification in progress...\nOrder processing on PhonePe side\nAttempt $_retryCount of $_maxRetries';
      });
    }
  }

  void _updateVerificationMessage(Map<String, dynamic> result) {
    setState(() {
      final source = result['source'] ?? 'phonepe_api';
      _message =
          'Payment verification in progress...\nAttempt $_retryCount of $_maxRetries\n'
          'Source: ${source == 'firestore_fallback' ? 'Fallback Check' : 'PhonePe Order Status API'}\n'
          '${result['message'] ?? 'Checking payment status...'}';
    });
  }

  void _handleUnexpectedResponse(Map<String, dynamic> result) {
    print('⚠️ Unexpected response from PhonePe Order Status API: $result');

    if (_retryCount >= _maxRetries) {
      _handleMaxRetriesReached();
    } else {
      setState(() {
        _message =
            'Unexpected payment status...\nAttempt $_retryCount of $_maxRetries\nRetrying verification...';
      });
    }
  }

  void _handleMaxRetriesReached() {
    print('⚠️ Maximum PhonePe Order Status API verification retries reached');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();

    if (mounted) {
      setState(() {
        _status = 'timeout';
        _message = 'Payment verification is taking longer than expected.\n'
            'We\'ve checked with PhonePe Order Status API ${_retryCount} times.\n'
            'If payment was successful, your order will be processed automatically.\n'
            'Please check your order history or contact support.';
      });
    }
  }

  void _handleVerificationTimeout() {
    print(
        '⏰ Payment verification timeout after ${_verificationTimeoutSeconds} seconds');

    _verificationTimer?.cancel();

    if (mounted) {
      setState(() {
        _status = 'timeout';
        _message = 'Payment verification timed out after 5 minutes.\n'
            'PhonePe Order Status API was checked ${_retryCount} times.\n'
            'If payment was successful on PhonePe, your order will be processed automatically.\n'
            'Please check your order history.';
      });
    }
  }

  void _handleVerificationError(String error) {
    print('💥 Payment verification error: $error');

    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();

    if (mounted) {
      setState(() {
        _status = 'failed';
        _message = 'Verification failed due to system error.\n'
            'PhonePe Order Status API error after ${_retryCount} attempts.\n'
            'If payment was successful on PhonePe, please contact support.';
      });
    }
  }

  void _retryVerification() {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _status = 'verifying';
      _message =
          'Retrying payment verification using PhonePe Order Status API...';
      _retryCount = 0;
    });

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
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'timeout':
        return Colors.orange;
      case 'not_found':
        return Colors.blue;
      default:
        return Colors.blue;
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
        return Icons.refresh;
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
        return 'Verifying with PhonePe';
    }
  }

  String _getVerificationMethod() {
    if (_verificationResult?['source'] == 'firestore_fallback') {
      return 'Firestore Fallback';
    }
    return 'PhonePe Order Status API';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon with Animation
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 3,
                      ),
                    ),
                    child: _status == 'verifying'
                        ? const Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : Icon(
                            _getStatusIcon(),
                            size: 60,
                            color: _getStatusColor(),
                          ),
                  ),

                  const SizedBox(height: 30),

                  // Status Title
                  Text(
                    _getStatusTitle(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // Verification Method Badge
                  if (_status != 'verifying') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _getStatusColor().withOpacity(0.3)),
                      ),
                      child: Text(
                        'Verified via: ${_getVerificationMethod()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Using PhonePe Order Status API',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Status Message
                  Text(
                    _message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Order Details Card
                  if (_pendingOrderData != null) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Order Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: _getStatusColor()),
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
                            const SizedBox(height: 15),
                            _buildDetailRow('Order ID',
                                widget.orderId.substring(0, 12).toUpperCase()),
                            _buildDetailRow('Amount',
                                '₹${_pendingOrderData!['total']?.toStringAsFixed(2) ?? '0.00'}'),
                            _buildDetailRow('Items',
                                '${(_pendingOrderData!['items'] as List?)?.length ?? 0} item(s)'),
                            _buildDetailRow('Customer',
                                '${_pendingOrderData!['customerDetails']?['name'] ?? 'N/A'}'),
                            if (_status != 'verifying') ...[
                              const SizedBox(height: 10),
                              _buildDetailRow('Verification Method',
                                  _getVerificationMethod()),
                              if (_retryCount > 0)
                                _buildDetailRow(
                                    'API Calls Made', _retryCount.toString()),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Payment Data Card (if available)
                  if (_paymentData != null && _status == 'success') ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment,
                                    color: Colors.green[600], size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Payment Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            if (_paymentData!['orderId'] != null)
                              _buildDetailRow('PhonePe Order ID',
                                  _paymentData!['orderId'].toString()),
                            if (_paymentData!['state'] != null)
                              _buildDetailRow('Payment State',
                                  _paymentData!['state'].toString()),
                            if (_paymentData!['amount'] != null)
                              _buildDetailRow('Amount (Paisa)',
                                  _paymentData!['amount'].toString()),
                            if (_paymentData!['paymentDetails'] != null &&
                                _paymentData!['paymentDetails'].isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Payment Details:',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              for (var detail
                                  in _paymentData!['paymentDetails'])
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, bottom: 2),
                                  child: Text(
                                    '• Mode: ${detail['paymentMode'] ?? 'N/A'}, Status: ${detail['state'] ?? 'N/A'}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  if (_status == 'verifying') ...[
                    // Progress Indicator
                    Container(
                      width: double.infinity,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Attempt $_retryCount of $_maxRetries • ${_getVerificationMethod()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Next check in ${_getVerificationInterval()} seconds',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Column(
                      children: [
                        if (_status == 'success') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/order-success'),
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('View Order Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _retryVerification,
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text('Retry Verification'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.home, size: 20),
                            label: const Text('Back to Home'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (_status == 'failed' || _status == 'timeout') ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showSupportDialog(context);
                              },
                              icon: const Icon(Icons.support_agent),
                              label: const Text('Contact Support'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Enhanced Information Section
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'About Payment Verification',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getInfoMessage(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_status == 'verifying') ...[
                          const SizedBox(height: 8),
                          Text(
                            'API Endpoint: /checkout/v2/order/{orderId}/status',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInfoMessage() {
    switch (_status) {
      case 'verifying':
        return 'We\'re using PhonePe\'s official Order Status API to verify your payment in real-time. Please wait while we confirm your transaction status. This may take up to 5 minutes.';
      case 'success':
        return 'Your payment has been successfully verified using PhonePe Order Status API. Your order has been confirmed and will be shipped via Delhivery.';
      case 'timeout':
        return 'Payment verification took longer than expected. We checked with PhonePe Order Status API ${_retryCount} times. If your payment was successful, it will be processed automatically within 24 hours.';
      case 'failed':
        return 'Payment verification via PhonePe Order Status API indicates the payment was not successful. If you believe this is an error or if you were charged, please contact support immediately.';
      default:
        return 'Payment verification is in progress using PhonePe\'s official Order Status API for accurate and real-time payment status checking.';
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.support_agent, color: Colors.blue),
              SizedBox(width: 8),
              Text('Contact Support'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('For assistance with your payment verification:'),
              const SizedBox(height: 16),
              _buildSupportItem(
                  Icons.email, 'Email', 'support@keiwaywellness.com'),
              _buildSupportItem(Icons.phone, 'Phone', '+91-XXXXXXXXXX'),
              _buildSupportItem(
                  Icons.schedule, 'Hours', '9 AM - 6 PM (Mon-Fri)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please include this information:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text('Order ID: ${widget.orderId}',
                        style: const TextStyle(fontSize: 11)),
                    Text('Verification Method: ${_getVerificationMethod()}',
                        style: const TextStyle(fontSize: 11)),
                    Text('API Calls Made: $_retryCount',
                        style: const TextStyle(fontSize: 11)),
                    Text('Status: $_status',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Copy order ID to clipboard functionality could be added here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ID: ${widget.orderId}'),
                    action: SnackBarAction(
                      label: 'Copy',
                      onPressed: () {
                        // Implement clipboard copy
                      },
                    ),
                  ),
                );
              },
              child: const Text('Copy Details'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupportItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
