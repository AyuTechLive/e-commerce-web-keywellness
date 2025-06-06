import 'package:flutter/material.dart';
import 'package:keiwaywellness/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({Key? key}) : super(key: key);

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final fetchedOrders = await adminProvider.getAllOrders();
    setState(() {
      orders = fetchedOrders;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text('No orders found.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = order['items'] as List<dynamic>? ?? [];
                    final createdAt = DateTime.fromMillisecondsSinceEpoch(
                      order['createdAt'] ?? 0,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          'Order #${order['id'].substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Total: ₹${order['total']?.toStringAsFixed(2) ?? '0.00'}'),
                            Text('Date: ${_formatDate(createdAt)}'),
                            Row(
                              children: [
                                const Text('Status: '),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                        order['status'] ?? 'pending'),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (order['status'] ?? 'pending')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (status) =>
                              _updateOrderStatus(order['id'], status),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'pending', child: Text('Pending')),
                            const PopupMenuItem(
                                value: 'confirmed', child: Text('Confirmed')),
                            const PopupMenuItem(
                                value: 'shipped', child: Text('Shipped')),
                            const PopupMenuItem(
                                value: 'delivered', child: Text('Delivered')),
                            const PopupMenuItem(
                                value: 'cancelled', child: Text('Cancelled')),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                '${item['name']} x ${item['quantity']}'),
                                          ),
                                          Text(
                                              '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 12),
                                const Text(
                                  'Shipping Address:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(order['shippingAddress'] ??
                                    'No address provided'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final error = await adminProvider.updateOrderStatus(orderId, status);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order status updated!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders(); // Refresh the orders list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}
