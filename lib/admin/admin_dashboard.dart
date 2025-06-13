// admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:keiwaywellness/admin/manage_categoy_screen.dart';
import 'package:keiwaywellness/admin/manage_order.dart';
import 'package:keiwaywellness/admin/managecategories.dart';
import 'package:keiwaywellness/admin/website_content.dart';

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid
                int crossAxisCount = 2;
                if (constraints.maxWidth > 600) crossAxisCount = 3;
                if (constraints.maxWidth > 900) crossAxisCount = 4;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                  children: [
                    _buildDashboardCard(
                      context,
                      'Website Content',
                      Icons.web,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const WebsiteContentManagementScreen(),
                        ),
                      ),
                      'Manage banners, stats, branding',
                    ),
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
                      'Add, edit, delete categories',
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
                      'Add, edit, delete products',
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
                      'View and manage orders',
                    ),
                    _buildDashboardCard(
                      context,
                      'Add Sample Data',
                      Icons.data_object,
                      Colors.teal,
                      () => _addSampleData(context),
                      'Populate with sample data',
                    ),
                    _buildDashboardCard(
                      context,
                      'Analytics',
                      Icons.analytics,
                      Colors.indigo,
                      () => _showComingSoon(context),
                      'View reports and analytics',
                    ),
                    _buildDashboardCard(
                      context,
                      'User Management',
                      Icons.people,
                      Colors.cyan,
                      () => _showComingSoon(context),
                      'Manage user accounts',
                    ),
                    _buildDashboardCard(
                      context,
                      'Settings',
                      Icons.settings,
                      Colors.grey,
                      () => _showComingSoon(context),
                      'App settings and config',
                    ),
                  ],
                );
              },
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
    String description,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Adding sample data...'),
                    ],
                  ),
                ),
              );

              final error = await adminProvider.addSampleData();
              Navigator.pop(context); // Close loading dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error == null
                        ? 'Sample data added successfully!'
                        : 'Error: $error',
                  ),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Data'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming Soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
