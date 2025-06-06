import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.home, color: Color(0xFF2E7D32)),
        onPressed: () => context.go('/'),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: const Text(
          'Wellness Store',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Stack(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.shopping_cart, color: Color(0xFF2E7D32)),
                  onPressed: () => context.go('/cart'),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartProvider.itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isAuthenticated) {
              return PopupMenuButton<String>(
                icon:
                    const Icon(Icons.account_circle, color: Color(0xFF2E7D32)),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      context.go('/profile');
                      break;
                    case 'logout':
                      authProvider.signOut();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 10),
                        Text('Hi, ${authProvider.userModel?.name ?? 'User'}'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 10),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Sign In',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
