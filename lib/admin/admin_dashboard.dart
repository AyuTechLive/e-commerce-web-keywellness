import 'package:flutter/material.dart';
import 'package:keiwaywellness/admin/manage_categoy_screen.dart';
import 'package:keiwaywellness/admin/manage_order.dart';
import 'package:keiwaywellness/providers/admin_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is admin (you can implement proper admin check)
        if (!authProvider.isAuthenticated ||
            authProvider.userModel?.email != 'admin@wellness.com') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 100, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('You need admin privileges to access this page'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
              ),
              IconButton(
                onPressed: () => authProvider.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildDashboardCard(
                  context,
                  'Manage Categories',
                  Icons.category,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesScreen(),
                    ),
                  ),
                ),
                _buildDashboardCard(
                  context,
                  'Manage Products',
                  Icons.inventory,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageProductsScreen(),
                    ),
                  ),
                ),
                _buildDashboardCard(
                  context,
                  'Manage Orders',
                  Icons.shopping_bag,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageOrdersScreen(),
                    ),
                  ),
                ),
                _buildDashboardCard(
                  context,
                  'Add Sample Data',
                  Icons.data_object,
                  Colors.purple,
                  () => _addSampleData(context),
                ),
                _buildDashboardCard(
                  context,
                  'Analytics',
                  Icons.analytics,
                  Colors.teal,
                  () => _showComingSoon(context),
                ),
                _buildDashboardCard(
                  context,
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => _showComingSoon(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSampleData(BuildContext context) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sample Data'),
        content: const Text(
          'This will add sample categories and products to your database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final error = await adminProvider.addSampleData();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error == null
                        ? 'Sample data added successfully!'
                        : 'Error: $error',
                  ),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Add Data'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming Soon!')),
    );
  }
}
