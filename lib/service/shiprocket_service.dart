// services/delhivery_service.dart - Firebase Functions Integration
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/order.dart';

class DelhiveryService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Check pincode serviceability via Firebase Functions
  static Future<Map<String, dynamic>?> checkServiceability(
      String pincode) async {
    try {
      print(
          '🔍 Checking serviceability for pincode via Firebase Functions: $pincode');

      final HttpsCallable callable =
          _functions.httpsCallable('checkDelhiveryServiceability');
      final result = await callable.call({'pincode': pincode});

      print('📥 Serviceability Response: ${result.data}');

      if (result.data['success'] == true) {
        return {
          'serviceable': result.data['serviceable'],
          'pincode': result.data['pincode'],
          'city': result.data['city'],
          'state': result.data['state'],
          'cod_available': result.data['cod_available'],
          'prepaid_available': result.data['prepaid_available'],
          'cash_available': result.data['cash_available'],
          'pickup_available': result.data['pickup_available'],
          'repl_available': result.data['repl_available'],
          'message': result.data['message'],
        };
      } else {
        return {
          'serviceable': false,
          'message': result.data['message'] ?? 'Serviceability check failed',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      print('💥 Firebase Functions Exception: ${e.code} - ${e.message}');

      return {
        'serviceable': false,
        'error': e.code,
        'message': _getErrorMessage(e.code),
        'statusCode': _getStatusCode(e.code),
      };
    } catch (e) {
      print('❌ Serviceability check error: $e');
      return {
        'serviceable': false,
        'error': 'unknown',
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Create order with Delhivery via Firebase Functions
  static Future<Map<String, dynamic>?> createOrder({
    required OrderModel order,
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> shippingAddress,
    String paymentMode = 'COD',
  }) async {
    try {
      print(
          '📦 Creating Delhivery order via Firebase Functions for: ${order.id}');
      print('💰 Payment mode: $paymentMode');

      final HttpsCallable callable =
          _functions.httpsCallable('createDelhiveryOrder');

      final requestData = {
        'orderId': order.id,
        'orderDate': order.createdAt.toIso8601String(),
        'customerDetails': customerDetails,
        'shippingAddress': shippingAddress,
        'items': order.items
            .map((item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                  'price': item.price,
                  'total': item.total,
                })
            .toList(),
        'total': order.total,
        'paymentMode': paymentMode,
      };

      print(
          '📋 Calling Firebase Function with data keys: ${requestData.keys.join(', ')}');

      final result = await callable.call(requestData);

      print('📥 Delhivery Create Order Response: ${result.data}');

      if (result.data['success'] == true) {
        print('✅ Delhivery order created successfully via Firebase Functions');
        return result.data;
      } else {
        throw Exception(
            'Delhivery order creation failed: ${result.data['error']}');
      }
    } on FirebaseFunctionsException catch (e) {
      print('💥 Firebase Functions Exception: ${e.code} - ${e.message}');
      print('Details: ${e.details}');
      rethrow;
    } catch (e) {
      print('❌ Delhivery order creation error: $e');
      rethrow;
    }
  }

  /// Track shipment via Firebase Functions
  static Future<Map<String, dynamic>?> trackShipment(String waybill) async {
    try {
      print('📍 Tracking shipment via Firebase Functions: $waybill');

      final HttpsCallable callable =
          _functions.httpsCallable('trackDelhiveryShipment');
      final result = await callable.call({'waybill': waybill});

      print('📥 Tracking Response: ${result.data}');

      if (result.data['success'] == true) {
        return result.data;
      } else {
        return {
          'success': false,
          'message': result.data['message'] ?? 'Tracking failed',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      print(
          '💥 Tracking Firebase Functions Exception: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.code,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Tracking error: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Tracking request failed',
      };
    }
  }

  /// Track shipment by order ID via Firebase Functions
  static Future<Map<String, dynamic>?> trackByOrderId(String orderId) async {
    try {
      print('📍 Tracking by order ID via Firebase Functions: $orderId');

      final HttpsCallable callable =
          _functions.httpsCallable('trackDelhiveryShipment');
      final result = await callable.call({'orderId': orderId});

      print('📥 Tracking by Order ID Response: ${result.data}');

      return result.data;
    } on FirebaseFunctionsException catch (e) {
      print(
          '💥 Tracking by Order ID Firebase Functions Exception: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.code,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Tracking by order ID error: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Tracking request failed',
      };
    }
  }

  /// Get bulk waybills via Firebase Functions
  static Future<List<String>?> fetchWaybills(int count) async {
    try {
      if (count > 100) {
        print('❌ Maximum 100 waybills can be fetched in one request');
        return null;
      }

      print('📦 Fetching $count waybills via Firebase Functions...');

      final HttpsCallable callable =
          _functions.httpsCallable('fetchDelhiveryWaybills');
      final result = await callable.call({'count': count});

      print('📥 Waybill Response: ${result.data}');

      if (result.data['success'] == true) {
        final waybills = List<String>.from(result.data['waybills'] ?? []);
        print('✅ Fetched ${waybills.length} waybills via Firebase Functions');
        return waybills;
      } else {
        return null;
      }
    } on FirebaseFunctionsException catch (e) {
      print(
          '💥 Waybill fetch Firebase Functions Exception: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Waybill fetch error: $e');
      return null;
    }
  }

  /// Test Delhivery connection via Firebase Functions
  static Future<bool> testConnection() async {
    try {
      print('🧪 Testing Delhivery connection via Firebase Functions...');

      final HttpsCallable callable =
          _functions.httpsCallable('testDelhiveryConnection');
      final result = await callable.call();

      print('📥 Connection Test Response: ${result.data}');

      if (result.data['success'] == true) {
        print('✅ Delhivery connection test successful via Firebase Functions');
        print('📋 Test result: ${result.data}');
        return true;
      } else {
        print('❌ Delhivery connection test failed via Firebase Functions');
        print('❌ Error: ${result.data['message']}');
        _printTroubleshootingInfo(result.data);
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      print(
          '💥 Connection test Firebase Functions Exception: ${e.code} - ${e.message}');
      print('Details: ${e.details}');
      return false;
    } catch (e) {
      print('❌ Delhivery connection test error: $e');
      return false;
    }
  }

  /// Print configuration information
  static void printConfiguration() {
    print('🚚 Delhivery Service Configuration:');
    print('🌐 Integration: Firebase Functions (Server-side)');
    print('🔗 Method: Cloud Functions Proxy');
    print('🔑 Authentication: Server-side token management');
    print('📋 Available Services: Serviceability, Order Creation, Tracking');
    print('✅ CORS Issue: Resolved via Firebase Functions');
    print('🔒 Security: Token secured on server-side');
  }

  /// Get error message based on Firebase Functions error code
  static String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'unauthenticated':
        return 'Authentication failed with Delhivery. Please contact support.';
      case 'permission-denied':
        return 'Permission denied. API access may not be enabled.';
      case 'invalid-argument':
        return 'Invalid request parameters provided.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  /// Get status code based on Firebase Functions error code
  static int _getStatusCode(String errorCode) {
    switch (errorCode) {
      case 'unauthenticated':
        return 401;
      case 'permission-denied':
        return 403;
      case 'invalid-argument':
        return 400;
      case 'internal':
        return 500;
      case 'unavailable':
        return 503;
      default:
        return 500;
    }
  }

  /// Print troubleshooting information based on error response
  static void _printTroubleshootingInfo(Map<String, dynamic> errorData) {
    print('🔧 Delhivery Troubleshooting Information:');
    print('');
    print('❌ Connection failed with details:');
    print('   Error Type: ${errorData['error']}');
    print('   Message: ${errorData['message']}');
    print('   Details: ${errorData['details']}');
    print('');

    if (errorData['error'] == 'authentication') {
      print('🔑 Authentication Issues:');
      print('   1. Check if Delhivery token is valid');
      print(
          '   2. Verify token is for correct environment (staging/production)');
      print('   3. Contact Delhivery support for API access');
      print('   4. Ensure account has API integration enabled');
    } else if (errorData['error'] == 'permission') {
      print('🚫 Permission Issues:');
      print('   1. API access may not be enabled for your account');
      print('   2. Contact Delhivery to enable API permissions');
      print('   3. Verify account type supports API integration');
    } else if (errorData['error'] == 'network') {
      print('🌐 Network Issues:');
      print('   1. Check Firebase Functions connectivity');
      print('   2. Verify internet connection');
      print('   3. Check if Delhivery services are available');
    }

    print('');
    print('📞 Delhivery Support:');
    print('   Email: clientservice@delhivery.com');
    print('   Subject: API Integration Support - Firebase Functions');
    print('');
    print('💡 Note: All API calls are now routed through Firebase Functions');
    print('   This resolves CORS issues and secures API credentials.');
  }

  /// Print authentication troubleshooting information
  static void printAuthTroubleshooting() {
    print('🔧 Delhivery Authentication Troubleshooting (Firebase Functions):');
    print('');
    print('📋 Current Setup:');
    print('   Integration: Server-side via Firebase Functions');
    print('   CORS: Resolved by server-side proxy');
    print('   Authentication: Managed server-side');
    print('');
    print('❌ If authentication is failing:');
    print('   1. Check Firebase Functions deployment');
    print('   2. Verify Delhivery token in Firebase Functions configuration');
    print('   3. Contact Delhivery for API access verification');
    print('   4. Check Firebase Functions logs for detailed errors');
    print('');
    print('🚀 Deploy Functions:');
    print('   cd functions && firebase deploy --only functions');
    print('');
    print('📞 Support:');
    print('   Delhivery: clientservice@delhivery.com');
    print('   Firebase: https://firebase.google.com/support');
  }
}
