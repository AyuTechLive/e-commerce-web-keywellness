import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo section
              GestureDetector(
                onTap: () => context.go('/'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'WellnessHub',
                      style: TextStyle(
                        color: Color(0xFF1A365D),
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation links
              Row(
                children: [
                  _buildNavLink('Home', true, () => context.go('/')),
                  const SizedBox(width: 32),
                  _buildNavLink('Products', false, () {}),
                  const SizedBox(width: 32),
                  _buildNavLink('Categories', false, () {}),
                  const SizedBox(width: 32),
                  _buildNavLink('About', false, () {}),
                  const SizedBox(width: 32),
                  _buildNavLink('Contact', false, () {}),
                ],
              ),

              // Action buttons
              Row(
                children: [
                  // Search button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF4A5568),
                        size: 22,
                      ),
                      onPressed: () {},
                      tooltip: 'Search',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Cart button with badge
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Color(0xFF4A5568),
                                size: 22,
                              ),
                              onPressed: () => context.go('/cart'),
                              tooltip: 'Shopping Cart',
                            ),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00D4AA),
                                        Color(0xFF4FD1C7)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    cartProvider.itemCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Wishlist button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFF4A5568),
                        size: 22,
                      ),
                      onPressed: () {},
                      tooltip: 'Wishlist',
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User account section
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isAuthenticated) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF00D4AA),
                                    child: Text(
                                      authProvider.userModel?.name
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Welcome back!',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        authProvider.userModel?.name ?? 'User',
                                        style: const TextStyle(
                                          color: Color(0xFF1A365D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF4A5568),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'profile':
                                  context.go('/profile');
                                  break;
                                case 'orders':
                                  context.go('/orders');
                                  break;
                                case 'settings':
                                  context.go('/settings');
                                  break;
                                case 'logout':
                                  authProvider.signOut();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              _buildPopupMenuItem(
                                'profile',
                                Icons.person_outline_rounded,
                                'My Profile',
                                'View and edit your profile',
                              ),
                              _buildPopupMenuItem(
                                'orders',
                                Icons.shopping_bag_outlined,
                                'My Orders',
                                'Track your purchases',
                              ),
                              _buildPopupMenuItem(
                                'settings',
                                Icons.settings_outlined,
                                'Settings',
                                'Account preferences',
                              ),
                              const PopupMenuDivider(),
                              _buildPopupMenuItem(
                                'logout',
                                Icons.logout_rounded,
                                'Sign Out',
                                'Logout from your account',
                                isDestructive: true,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Row(
                          children: [
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4A5568),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => context.go('/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4AA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00D4AA).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF00D4AA) : const Color(0xFF4A5568),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF00D4AA),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color:
                          isDestructive ? Colors.red : const Color(0xFF1A365D),
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
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
