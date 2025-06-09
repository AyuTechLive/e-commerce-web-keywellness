import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({Key? key}) : super(key: key);

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _latestOrderId;
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _shiprocketData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestOrder();
  }

  Future<void> _loadLatestOrder() async {
    try {
      if (_auth.currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the latest order for the current user
      final ordersQuery = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (ordersQuery.docs.isNotEmpty) {
        final orderDoc = ordersQuery.docs.first;
        _latestOrderId = orderDoc.id;
        _orderData = orderDoc.data();
        _shiprocketData = _orderData?['shiprocket'];

        print('📦 Latest order loaded: $_latestOrderId');
        print('📋 Shiprocket data: $_shiprocketData');
      }
    } catch (e) {
      print('❌ Error loading latest order: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getOrderStatus() {
    if (_orderData == null) return 'Unknown';

    final status = _orderData!['status'] ?? 'pending';
    final shippingStatus = _orderData!['shippingStatus'] ?? 'processing';

    if (shippingStatus != 'processing') {
      return _formatStatus(shippingStatus);
    }

    return _formatStatus(status);
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }

  Color _getStatusColor() {
    final status = _getOrderStatus().toLowerCase();
    if (status.contains('delivered')) return Colors.green;
    if (status.contains('shipped') || status.contains('transit'))
      return Colors.blue;
    if (status.contains('cancelled')) return Colors.red;
    return Colors.orange;
  }

  Future<void> _openTrackingUrl() async {
    if (_shiprocketData?['awb'] != null) {
      // Open Shiprocket tracking page
      final awb = _shiprocketData!['awb'];
      final trackingUrl = 'https://shiprocket.in/tracking/$awb';

      final uri = Uri.parse(trackingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open tracking URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyTrackingNumber() async {
    if (_shiprocketData?['awb'] != null) {
      // In a real app, you'd use clipboard package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tracking number: ${_shiprocketData!['awb']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40),
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading order details...'),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Success Message
                    const Text(
                      'Order Placed Successfully!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Thank you for your order. Your order has been confirmed and will be processed shortly.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (_latestOrderId != null) ...[
                      const SizedBox(height: 30),

                      // Order Details Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order ID and Status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Order ID',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _latestOrderId!
                                            .substring(0, 8)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor().withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: _getStatusColor()),
                                    ),
                                    child: Text(
                                      _getOrderStatus(),
                                      style: TextStyle(
                                        color: _getStatusColor(),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (_orderData != null) ...[
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 15),

                                // Order Amount
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Order Amount',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '₹${_orderData!['total']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Payment Method
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Payment Method',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.payment,
                                            size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          _orderData!['paymentId']
                                                      ?.isNotEmpty ==
                                                  true
                                              ? 'PhonePe (Paid)'
                                              : 'Cash on Delivery',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Shipping Info
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Shipping Partner',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.local_shipping,
                                            size: 16, color: Colors.green[600]),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Shiprocket',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],

                              // Shiprocket Tracking Section
                              if (_shiprocketData != null) ...[
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 15),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.track_changes,
                                              color: Colors.blue[600]),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Shipment Tracking',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (_shiprocketData!['shipmentId'] !=
                                          null) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Shipment ID',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                            Text(
                                              _shiprocketData!['shipmentId']
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (_shiprocketData!['awb'] != null) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'AWB Number',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  _shiprocketData!['awb']
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      _copyTrackingNumber,
                                                  icon: const Icon(Icons.copy,
                                                      size: 16),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Track Order Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _openTrackingUrl,
                                            icon: const Icon(
                                                Icons.track_changes,
                                                size: 16),
                                            label:
                                                const Text('Track Your Order'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[600],
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        const Text(
                                          'Tracking information will be available once your order is picked up by our shipping partner.',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.schedule,
                                          color: Colors.orange[600]),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Preparing for Shipment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Your order is being prepared and will be shipped via Shiprocket soon. You\'ll receive tracking details once it\'s dispatched.',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Continue Shopping',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/profile'),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('View All Orders'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (_shiprocketData != null &&
                            _shiprocketData!['awb'] != null) ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openTrackingUrl,
                              icon: const Icon(Icons.local_shipping),
                              label: const Text('Track Shipment'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[600]!),
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

                    const SizedBox(height: 30),

                    // Additional Information
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'What happens next?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildTimelineItem(
                            icon: Icons.verified,
                            title: 'Order Confirmed',
                            subtitle:
                                'Your order has been received and confirmed',
                            isCompleted: true,
                          ),
                          _buildTimelineItem(
                            icon: Icons.inventory,
                            title: 'Processing',
                            subtitle:
                                'We\'re preparing your items for shipment',
                            isCompleted: _getOrderStatus() != 'Order Confirmed',
                          ),
                          _buildTimelineItem(
                            icon: Icons.local_shipping,
                            title: 'Shipped',
                            subtitle: 'Your order is on its way via Shiprocket',
                            isCompleted:
                                _getOrderStatus().contains('Shipped') ||
                                    _getOrderStatus().contains('Transit') ||
                                    _getOrderStatus().contains('Delivered'),
                          ),
                          _buildTimelineItem(
                            icon: Icons.home,
                            title: 'Delivered',
                            subtitle: 'Your order has been delivered',
                            isCompleted:
                                _getOrderStatus().contains('Delivered'),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Support
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.support_agent, color: Colors.blue[600]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Help?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Contact our support team for any questions about your order.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Implement contact support functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Support: +91-XXXXXXXXXX'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            child: const Text('Contact'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: 18,
                color: isCompleted ? Colors.white : Colors.grey[600],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[600],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
