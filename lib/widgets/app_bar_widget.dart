import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;

  const CustomAppBar({
    Key? key,
    this.currentRoute = '/',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        final bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

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
            toolbarHeight: isMobile ? 70 : 80,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            title: isMobile
                ? _buildMobileAppBar(context)
                : _buildDesktopAppBar(context, isTablet),
          ),
        );
      },
    );
  }

  Widget _buildMobileAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mobile Logo
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF4FD1C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'WellnessHub',
                  style: TextStyle(
                    color: Color(0xFF1A365D),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Mobile Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cart button with badge
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFF4A5568),
                            size: 20,
                          ),
                          onPressed: () => context.go('/cart'),
                          tooltip: 'Shopping Cart',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        if (cartProvider.itemCount > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00D4AA),
                                    Color(0xFF4FD1C7)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4AA)
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                cartProvider.itemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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

              // Mobile Menu Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF4A5568),
                        size: 20,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'home':
                            context.go('/');
                            break;
                          case 'products':
                            context.go('/products');
                            break;
                          case 'categories':
                            context.go('/categories');
                            break;
                          case 'about':
                            context.go('/about');
                            break;
                          case 'contact':
                            context.go('/contact');
                            break;
                          case 'search':
                            // Handle search
                            break;
                          case 'wishlist':
                            // Handle wishlist
                            break;
                          case 'login':
                            context.go('/login');
                            break;
                          case 'register':
                            context.go('/register');
                            break;
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
                        // Navigation Items
                        _buildMobileMenuItem(
                            'home', Icons.home_rounded, 'Home', null),
                        _buildMobileMenuItem('products',
                            Icons.inventory_2_rounded, 'Products', null),
                        _buildMobileMenuItem('categories',
                            Icons.category_rounded, 'Categories', null),
                        _buildMobileMenuItem(
                            'about', Icons.info_rounded, 'About', null),
                        _buildMobileMenuItem('contact',
                            Icons.contact_support_rounded, 'Contact', null),

                        const PopupMenuDivider(),

                        // Action Items
                        _buildMobileMenuItem(
                            'search', Icons.search_rounded, 'Search', null),
                        _buildMobileMenuItem('wishlist',
                            Icons.favorite_border_rounded, 'Wishlist', null),

                        const PopupMenuDivider(),

                        // Auth Items
                        if (authProvider.isAuthenticated) ...[
                          _buildMobileMenuItem(
                              'profile',
                              Icons.person_outline_rounded,
                              'My Profile',
                              authProvider.userModel?.name ?? 'User'),
                          _buildMobileMenuItem('orders',
                              Icons.shopping_bag_outlined, 'My Orders', null),
                          _buildMobileMenuItem('settings',
                              Icons.settings_outlined, 'Settings', null),
                          const PopupMenuDivider(),
                          _buildMobileMenuItem(
                              'logout', Icons.logout_rounded, 'Sign Out', null,
                              isDestructive: true),
                        ] else ...[
                          _buildMobileMenuItem(
                              'login', Icons.login_rounded, 'Sign In', null),
                          _buildMobileMenuItem('register',
                              Icons.person_add_rounded, 'Get Started', null),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Desktop Logo
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

          // Desktop Navigation Links
          if (!isTablet)
            Row(
              children: [
                _buildNavLink('Home', _isActive('/'), () => context.go('/')),
                const SizedBox(width: 32),
                _buildNavLink(
                    'Products',
                    _isActive('/products') || _isActive('/all-products'),
                    () => context.go('/products')),
                const SizedBox(width: 32),
                _buildNavLink('Categories', _isActive('/categories'),
                    () => context.go('/categories')),
                const SizedBox(width: 32),
                _buildNavLink(
                    'About', _isActive('/about'), () => context.go('/about')),
                const SizedBox(width: 32),
                _buildNavLink('Contact', _isActive('/contact'),
                    () => context.go('/contact')),
              ],
            ),

          // Desktop Action buttons
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  bool _isActive(String route) {
    if (route == '/' && currentRoute == '/') return true;
    if (route != '/' && currentRoute.startsWith(route)) return true;
    return false;
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

  PopupMenuItem<String> _buildMobileMenuItem(
    String value,
    IconData icon,
    String title,
    String? subtitle, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF00D4AA),
                size: 16,
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
                  if (subtitle != null)
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
