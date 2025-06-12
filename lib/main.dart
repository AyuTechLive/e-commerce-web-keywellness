// main.dart - Updated with Payment Verification Route
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:keiwaywellness/admin/admin_dashboard.dart';
import 'package:keiwaywellness/admin/admin_login.dart';
import 'package:keiwaywellness/firebase_options.dart';
import 'package:keiwaywellness/providers/admin_provider.dart';
import 'package:keiwaywellness/providers/auth_provider.dart';
import 'package:keiwaywellness/providers/cart_provider.dart';
import 'package:keiwaywellness/providers/category_provider.dart';
import 'package:keiwaywellness/providers/product_provider.dart';
import 'package:keiwaywellness/providers/website_content_provider.dart';
import 'package:keiwaywellness/screens/allcategories.dart';
import 'package:keiwaywellness/screens/cart_screen.dart';
import 'package:keiwaywellness/screens/category_product_screen.dart';
import 'package:keiwaywellness/screens/checkout_screen.dart';
import 'package:keiwaywellness/screens/home_screen.dart';
import 'package:keiwaywellness/screens/login_screen.dart';
import 'package:keiwaywellness/screens/order_success_screen.dart';
import 'package:keiwaywellness/screens/page_screen.dart';
import 'package:keiwaywellness/screens/product_detail_screen.dart';
import 'package:keiwaywellness/screens/product_screen.dart';
import 'package:keiwaywellness/screens/profile_screen.dart';
import 'package:keiwaywellness/screens/register_screen.dart';
import 'package:keiwaywellness/screens/payment_verification_screen.dart'; // Add this import
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => WebsiteContentProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Keiway Wellness',
            theme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: const Color(0xFF2E7D32),
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
              ),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsConditionsScreen(),
    ),
    GoRoute(
      path: '/refund',
      builder: (context, state) => const RefundPolicyScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailScreen(productId: productId);
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    // ADD THIS ROUTE - Payment Verification Screen
    GoRoute(
      path: '/payment-verification/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return PaymentVerificationScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/order-success',
      builder: (context, state) => const OrderSuccessScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const AllProductsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final categoryId = state.pathParameters['id']!;
        return CategoryProductsScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboard(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  },
);
