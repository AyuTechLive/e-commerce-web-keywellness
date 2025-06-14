import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keiwaywellness/helper/delihvery_tracker_parser.dart';
import 'package:keiwaywellness/models/order.dart';
import 'package:keiwaywellness/screens/profile_screen.dart';
import 'package:keiwaywellness/service/shiprocket_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_bar_widget.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  OrderModel? order;
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? trackingData;
  bool isLoadingTracking = false;

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
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!doc.exists) {
        setState(() {
          error = 'Order not found';
          isLoading = false;
        });
        return;
      }

      final orderData = doc.data() as Map<String, dynamic>;

      // Verify order belongs to current user
      if (orderData['userId'] != authProvider.user!.uid) {
        setState(() {
          error = 'Unauthorized access';
          isLoading = false;
        });
        return;
      }

      setState(() {
        order = OrderModel.fromMap(orderData, doc.id);
        isLoading = false;
      });

      _fadeController.forward();

      // Load tracking data if available
      if (order!.delhivery != null && order!.delhivery!['waybill'] != null) {
        _loadTrackingData();
      }
    } catch (e) {
      setState(() {
        error = 'Error loading order: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTrackingData() async {
    if (order?.delhivery?['waybill'] == null) return;

    setState(() {
      isLoadingTracking = true;
    });

    try {
      final waybill = order!.delhivery!['waybill'];
      final result = await DelhiveryService.trackShipment(waybill: waybill);

      if (result != null && result['success'] == true) {
        setState(() {
          trackingData = result;
          isLoadingTracking = false;
        });
      } else {
        setState(() {
          isLoadingTracking = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingTracking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: CustomAppBar(
          // title: 'Order Details',
          // leading: IconButton(
          //   onPressed: () => context.pop(),
          //   icon: const Icon(Icons.arrow_back),
          // ),
          ),
      body: isLoading
          ? _buildLoadingState()
          : error != null
              ? _buildErrorState()
              : order == null
                  ? _buildNotFoundState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildOrderDetails(),
                    ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Order',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The order you\'re looking for doesn\'t exist or has been removed.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
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
                // Order Header
                _buildOrderHeader(isMobile),
                const SizedBox(height: 24),

                if (isMobile)
                  Column(
                    children: [
                      //  _buildOrderStatus(isMobile),
                      const SizedBox(height: 24),
                      if (order!.hasDiscounts) ...[
                        _buildDiscountSummary(isMobile),
                        const SizedBox(height: 24),
                      ],
                      _buildOrderItems(isMobile),
                      const SizedBox(height: 24),
                      _buildShippingDetails(isMobile),
                      const SizedBox(height: 24),
                      _buildPaymentDetails(isMobile),
                      if (order!.delhivery != null &&
                          order!.delhivery!['waybill'] != null) ...[
                        const SizedBox(height: 24),
                        _buildTrackingSection(isMobile),
                      ],
                    ],
                  )
                else
                  Column(
                    children: [
                      // Top row - Status and Actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Expanded(
                          //   flex: 2,
                          //   child: _buildOrderStatus(isMobile),
                          // ),
                          const SizedBox(width: 24),
                          if (order!.delhivery != null &&
                              order!.delhivery!['waybill'] != null)
                            Expanded(
                              flex: 1,
                              child: _buildTrackingSection(isMobile),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Discount Summary (if applicable)
                      if (order!.hasDiscounts) ...[
                        _buildDiscountSummary(isMobile),
                        const SizedBox(height: 24),
                      ],

                      // Main content row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isTablet ? 3 : 2,
                            child: Column(
                              children: [
                                _buildOrderItems(isMobile),
                                const SizedBox(height: 24),
                                _buildShippingDetails(isMobile),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildPaymentDetails(isMobile),
                          ),
                        ],
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

  Widget _buildOrderHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
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
                        'Order #${order!.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placed on ${_formatDate(order!.createdAt)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(order!.id),
                  icon: const Icon(
                    Icons.copy,
                    color: Colors.white70,
                  ),
                  tooltip: 'Copy Order ID',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderStat(
                    'Total Amount',
                    '₹${order!.total.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHeaderStat(
                    'Items',
                    '${order!.items.length}',
                    Icons.shopping_bag,
                  ),
                ),
                if (order!.hasDiscounts) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildHeaderStat(
                      'Saved',
                      '₹${order!.totalSavings?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.savings,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildOrderStatus(bool isMobile) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 20,
  //           offset: const Offset(0, 10),
  //         ),
  //       ],
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(isMobile ? 20 : 24),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: _getStatusColor(order!.status),
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Icon(
  //                   _getStatusIcon(order!.status),
  //                   color: Colors.white,
  //                   size: 24,
  //                 ),
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Order Status',
  //                       style: TextStyle(
  //                         fontSize: isMobile ? 16 : 18,
  //                         fontWeight: FontWeight.w700,
  //                         color: const Color(0xFF1A365D),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 6,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: _getStatusColor(order!.status),
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: Text(
  //                         order!.status.toUpperCase(),
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 20),

  //           // Status Timeline
  //           _buildStatusTimeline(),

  //           const SizedBox(height: 20),

  //           // Payment Status
  //           Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: _getPaymentStatusColor(order!.paymentStatus),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Icon(
  //                   _getPaymentStatusIcon(order!.paymentStatus),
  //                   color: Colors.white,
  //                   size: 16,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Payment Status',
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: Color(0xFF1A365D),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 2),
  //                   Text(
  //                     order!.paymentStatus.toUpperCase(),
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.bold,
  //                       color: _getPaymentStatusColor(order!.paymentStatus),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatusTimeline() {
    final statuses = ['pending', 'confirmed', 'shipped', 'delivered'];
    final currentIndex = statuses.indexOf(order!.status.toLowerCase());

    return Row(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? _getStatusColor(order!.status)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: _getStatusColor(order!.status),
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.substring(0, 1).toUpperCase() +
                          status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted
                            ? _getStatusColor(order!.status)
                            : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < statuses.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? _getStatusColor(order!.status)
                        : Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 30),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscountSummary(bool isMobile) {
    if (!order!.hasDiscounts) return const SizedBox.shrink();

    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
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
                    '🎉 Discount Applied!',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You saved ₹${order!.totalSavings?.toStringAsFixed(2)} on this order',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
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
              child: Column(
                children: [
                  Text(
                    '₹${order!.totalSavings?.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'SAVED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildOrderItems(bool isMobile) {
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Order Items (${order!.items.length})',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A365D),
                    ),
                  ),
                ),
                if (order!.hasDiscounts)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DISCOUNTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Items List
            ...order!.items
                .map((item) => InkWell(
                      onTap: () {
                        // Navigate to product detail page
                        context.go('/product/${item.productId}');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFBFC),
                          borderRadius: BorderRadius.circular(16),
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
                              width: isMobile ? 60 : 80,
                              height: isMobile ? 60 : 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        );
                                      },
                                    ),
                                    // Discount Badge
                                    if (item.hasDiscount)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${item.discountPercentage.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Clickable indicator
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.open_in_new,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A365D),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),

                                  // Quantity and Package Info
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF667EEA),
                                              Color(0xFF764BA2)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Qty: ${item.quantity}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (item.formattedProductQuantity
                                          .isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.formattedProductQuantity,
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (item.hasDiscount) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                  const SizedBox(height: 8),

                                  // Price Information
                                  if (item.hasDiscount) ...[
                                    Row(
                                      children: [
                                        Text(
                                          '₹${item.originalPrice!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'each',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You saved ₹${item.savings.toStringAsFixed(2)} on this item',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '₹${item.price.toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
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
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00D4AA),
                                        Color(0xFF4FD1C7)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (item.hasDiscount) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saved ₹${item.savings.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),

            // Order Totals
            if (order!.hasDiscounts) ...[
              _buildSummaryRow('Original Total',
                  '₹${order!.originalTotal?.toStringAsFixed(2) ?? '0.00'}'),
              _buildSummaryRow('Discount',
                  '-₹${order!.totalSavings?.toStringAsFixed(2) ?? '0.00'}',
                  valueColor: Colors.green),
              const SizedBox(height: 8),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
            ],
            _buildSummaryRow('Subtotal', '₹${order!.total.toStringAsFixed(2)}'),
            _buildSummaryRow('Shipping', 'Free',
                subtitle: 'Free shipping applied'),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Total Amount',
              '₹${order!.total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetails(bool isMobile) {
    final shippingAddress = order!.shippingAddress;
    final customerDetails = order!.customerDetails;

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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Shipping Details',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A365D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Information
            _buildInfoSection(
              'Customer Information',
              [
                'Name: ${customerDetails['name']} ${customerDetails['lastName'] ?? ''}',
                'Email: ${customerDetails['email']}',
                'Phone: ${customerDetails['phone']}',
              ],
              Icons.person,
              Colors.blue,
            ),

            const SizedBox(height: 20),

            // Shipping Address
            _buildInfoSection(
              'Delivery Address',
              [
                shippingAddress['name']?.toString() ?? 'N/A',
                shippingAddress['addressLine1']?.toString() ?? '',
                if (shippingAddress['addressLine2'] != null &&
                    shippingAddress['addressLine2'].toString().isNotEmpty)
                  shippingAddress['addressLine2'].toString(),
                '${shippingAddress['city']}, ${shippingAddress['state']} - ${shippingAddress['pinCode']}',
                shippingAddress['country']?.toString() ?? 'India',
              ].where((line) => line.isNotEmpty).toList(),
              Icons.location_on,
              Colors.green,
            ),

            if (order!.delhivery != null) ...[
              const SizedBox(height: 20),
              _buildInfoSection(
                'Shipping Information',
                [
                  if (order!.delhivery!['waybill'] != null)
                    'AWB: ${order!.delhivery!['waybill']}',
                  'Carrier: Delhivery',
                  if (order!.shippingStatus != null)
                    'Status: ${order!.shippingStatus}',
                ].where((line) => line.isNotEmpty).toList(),
                Icons.inventory,
                Colors.orange,
                copyableValue: order!.delhivery!['waybill']?.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(bool isMobile) {
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A365D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor(order!.paymentStatus)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getPaymentStatusColor(order!.paymentStatus),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(order!.paymentStatus),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPaymentStatusIcon(order!.paymentStatus),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order!.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getPaymentStatusColor(order!.paymentStatus),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Information
            if (order!.paymentData != null) ...[
              _buildInfoSection(
                'Payment Information',
                [
                  'Method: ${order!.paymentData!['paymentMethod']?.toString() ?? 'PhonePe'}',
                  'Transaction ID: ${order!.paymentData!['transactionId']?.toString() ?? order!.id}',
                  if (order!.paymentData!['paymentDate'] != null)
                    'Payment Date: ${_formatDate(DateTime.parse(order!.paymentData!['paymentDate'].toString()))}',
                ],
                Icons.receipt,
                Colors.purple,
                copyableValue:
                    order!.paymentData!['transactionId']?.toString() ??
                        order!.id,
              ),
            ] else ...[
              _buildInfoSection(
                'Payment Information',
                [
                  'Method: PhonePe',
                  'Transaction ID: ${order!.id}',
                  'Payment Date: ${_formatDate(order!.createdAt)}',
                ],
                Icons.receipt,
                Colors.purple,
                copyableValue: order!.id,
              ),
            ],

            const SizedBox(height: 20),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1),
                    const Color(0xFF764BA2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  if (order!.hasDiscounts) ...[
                    _buildSummaryRow('Original Amount',
                        '₹${order!.originalTotal?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildSummaryRow('Total Savings',
                        '-₹${order!.totalSavings?.toStringAsFixed(2) ?? '0.00'}',
                        valueColor: Colors.green),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                  ],
                  _buildSummaryRow(
                      'Amount Paid', '₹${order!.total.toStringAsFixed(2)}',
                      isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingSection(bool isMobile) {
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Track Package',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A365D),
                    ),
                  ),
                ),
                if (isLoadingTracking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (trackingData != null) ...[
              // Current Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getTrackingStatusColor(
                              trackingData!['current_status'] ?? '')
                          .withOpacity(0.1),
                      _getTrackingStatusColor(
                              trackingData!['current_status'] ?? '')
                          .withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getTrackingStatusColor(
                        trackingData!['current_status'] ?? ''),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getTrackingStatusIcon(
                          trackingData!['current_status'] ?? ''),
                      size: 32,
                      color: _getTrackingStatusColor(
                          trackingData!['current_status'] ?? ''),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trackingData!['current_status'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getTrackingStatusColor(
                            trackingData!['current_status'] ?? ''),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (trackingData!['current_description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trackingData!['current_description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tracking Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadTrackingData,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetailedTrackingDialog(),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00D4AA),
                        side: const BorderSide(color: Color(0xFF00D4AA)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // No tracking data available
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tracking information will be available once the package is shipped',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadTrackingData,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Check Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<String> items,
    IconData icon,
    Color color, {
    String? copyableValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (copyableValue != null)
                IconButton(
                  onPressed: () => _copyToClipboard(copyableValue),
                  icon: Icon(Icons.copy, size: 16, color: color),
                  tooltip: 'Copy',
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    String? subtitle,
    Color? valueColor,
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
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? const Color(0xFF1A365D) : Colors.grey[700],
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
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDetailedTrackingDialog() {
    showDialog(
      context: context,
      builder: (context) => TrackingDialog(order: order!),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Copied: $text'),
          ],
        ),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
      case 'cancelled':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getTrackingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'order shipped':
      case 'manifested':
        return Colors.blue;
      case 'in transit':
      case 'processing':
        return Colors.orange;
      case 'out for delivery':
        return Colors.green;
      case 'delivered':
        return Colors.green[700]!;
      case 'delivery exception':
      case 'exception':
        return Colors.amber;
      case 'returned':
      case 'rto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrackingStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'order shipped':
      case 'manifested':
        return Icons.local_shipping;
      case 'in transit':
      case 'processing':
        return Icons.local_shipping;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'delivery exception':
      case 'exception':
        return Icons.warning;
      case 'returned':
      case 'rto':
        return Icons.undo;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// TrackingDialog class is already defined in the profile_screen.dart file
// You can reuse the same TrackingDialog widget
