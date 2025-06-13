// services/delhivery_service.dart - Complete Flutter Delhivery Integration
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:keiwaywellness/helper/delihvery_tracker_parser.dart';
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

  /// Create Delhivery shipment with structured address data
  static Future<Map<String, dynamic>?> createShipment({
    required String orderId,
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> shippingAddress,
    required List<CartItemModel> items,
    required double total,
    String paymentMode = 'Prepaid',
  }) async {
    try {
      print(
          '📦 Creating Delhivery shipment via Firebase Functions for: $orderId');
      print('💰 Payment mode: $paymentMode');

      final HttpsCallable callable =
          _functions.httpsCallable('createDelhiveryShipment');

      // Prepare structured address data
      final addressData = {
        'name': shippingAddress['name'] ?? customerDetails['name'],
        'addressLine1':
            shippingAddress['addressLine1'] ?? shippingAddress['address'],
        'addressLine2': shippingAddress['addressLine2'] ?? '',
        'city': shippingAddress['city'],
        'state': shippingAddress['state'],
        'pinCode': shippingAddress['pinCode'] ?? shippingAddress['pincode'],
        'phone': customerDetails['phone'],
        'country': 'India'
      };

      final requestData = {
        'orderId': orderId,
        'customerDetails': {
          'name': customerDetails['name'],
          'lastName': customerDetails['lastName'] ?? '',
          'email': customerDetails['email'],
          'phone': customerDetails['phone'],
        },
        'shippingAddress': addressData,
        'items': items
            .map((item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                  'price': item.price,
                  'total': item.total,
                  'originalPrice': item.originalPrice,
                })
            .toList(),
        'total': total,
        'paymentMode': paymentMode,
      };

      print('📋 Calling Firebase Function with structured address data');

      final result = await callable.call(requestData);

      print('📥 Delhivery Shipment Response: ${result.data}');

      if (result.data['success'] == true) {
        print(
            '✅ Delhivery shipment created successfully via Firebase Functions');
        return result.data;
      } else {
        throw Exception(
            'Delhivery shipment creation failed: ${result.data['error']}');
      }
    } on FirebaseFunctionsException catch (e) {
      print('💥 Firebase Functions Exception: ${e.code} - ${e.message}');
      print('Details: ${e.details}');
      rethrow;
    } catch (e) {
      print('❌ Delhivery shipment creation error: $e');
      rethrow;
    }
  }

  /// Track shipment by waybill or order ID
  static Future<Map<String, dynamic>?> trackShipment({
    String? waybill,
    String? orderId,
  }) async {
    try {
      if (waybill == null && orderId == null) {
        throw Exception('Either waybill or orderId is required');
      }

      print('📍 Tracking shipment via Firebase Functions...');
      if (waybill != null) print('📦 Waybill: $waybill');
      if (orderId != null) print('🆔 Order ID: $orderId');

      final HttpsCallable callable =
          _functions.httpsCallable('trackDelhiveryShipment');
      final requestData = <String, dynamic>{};

      if (waybill != null) requestData['waybill'] = waybill;
      if (orderId != null) requestData['orderId'] = orderId;

      final result = await callable.call(requestData);

      print('📥 Raw Tracking Response: ${result.data}');

      if (result.data['success'] == true) {
        // Parse the raw Delhivery response into user-friendly format
        final rawData = result.data;

        // If we have detailed shipment data, parse it
        if (rawData['shipment_info'] != null) {
          final parsedData = DelhiveryTrackingParser.parseTrackingData({
            'ShipmentData': [
              {'Shipment': rawData['shipment_info']}
            ]
          });

          if (parsedData['success'] == true) {
            return parsedData;
          }
        }

        // Fallback to original data format
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

  /// Get comprehensive order tracking information
  static Future<Map<String, dynamic>?> getOrderTracking(String orderId) async {
    try {
      print('📍 Getting comprehensive order tracking for: $orderId');

      final HttpsCallable callable =
          _functions.httpsCallable('getOrderTracking');
      final result = await callable.call({'orderId': orderId});

      print('📥 Order Tracking Response: ${result.data}');

      if (result.data['success'] == true) {
        return result.data['tracking_info'];
      } else {
        return {
          'success': false,
          'message': result.data['message'] ?? 'Order tracking failed',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      print(
          '💥 Order Tracking Firebase Functions Exception: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.code,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Order tracking error: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Order tracking request failed',
      };
    }
  }

  /// Retry failed Delhivery shipment creation
  static Future<Map<String, dynamic>?> retryShipment(String orderId) async {
    try {
      print('🔄 Retrying Delhivery shipment for: $orderId');

      final HttpsCallable callable =
          _functions.httpsCallable('retryDelhiveryShipment');
      final result = await callable.call({'orderId': orderId});

      print('📥 Retry Response: ${result.data}');
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      print('💥 Retry Firebase Functions Exception: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.code,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Retry error: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Retry request failed',
      };
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
    print('🚚 Enhanced Delhivery Service Configuration:');
    print('🌐 Integration: Firebase Functions (Server-side)');
    print('🔗 Method: Cloud Functions Proxy with structured address handling');
    print('🔑 Authentication: Server-side token management');
    print(
        '📋 Available Services: Serviceability, Shipment Creation, Real-time Tracking');
    print(
        '📍 Address Format: Structured fields (addressLine1, city, state, pinCode)');
    print(
        '📦 Shipment Features: Automatic retry, waybill generation, tracking URLs');
    print(
        '🚛 Tracking Methods: By waybill, by order ID, comprehensive order tracking');
    print('✅ CORS Issue: Resolved via Firebase Functions');
    print('🔒 Security: Token secured on server-side');
    print(
        '🎯 Integration Points: Checkout, Payment Verification, Order Success');
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
    print('🔧 Enhanced Delhivery Troubleshooting Information:');
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
    } else if (errorData['error'] == 'address') {
      print('📍 Address Issues:');
      print('   1. Ensure all required address fields are provided');
      print('   2. Verify pincode format (6 digits)');
      print('   3. Check if address components are properly structured');
      print('   4. Confirm serviceability for the pincode');
    }

    print('');
    print('📞 Delhivery Support:');
    print('   Email: clientservice@delhivery.com');
    print('   Subject: API Integration Support - Firebase Functions');
    print('');
    print('💡 Enhanced Features:');
    print('   - Structured address handling');
    print('   - Real-time shipment tracking');
    print('   - Automatic retry mechanisms');
    print('   - Comprehensive order tracking');
    print('   - Waybill generation and management');
  }

  /// Validate address structure before creating shipment
  static Map<String, String> validateAddressStructure(
      Map<String, dynamic> address) {
    final errors = <String, String>{};

    if (address['addressLine1'] == null ||
        address['addressLine1'].toString().trim().isEmpty) {
      errors['addressLine1'] = 'Address line 1 is required';
    }

    if (address['city'] == null || address['city'].toString().trim().isEmpty) {
      errors['city'] = 'City is required';
    }

    if (address['state'] == null ||
        address['state'].toString().trim().isEmpty) {
      errors['state'] = 'State is required';
    }

    final pincode = address['pinCode'] ?? address['pincode'];
    if (pincode == null || pincode.toString().trim().isEmpty) {
      errors['pincode'] = 'PIN code is required';
    } else if (!RegExp(r'^\d{6}$').hasMatch(pincode.toString())) {
      errors['pincode'] = 'PIN code must be 6 digits';
    }

    return errors;
  }

  /// Format address for display
  static String formatAddressForDisplay(Map<String, dynamic> address) {
    final parts = <String>[];

    if (address['name'] != null && address['name'].toString().isNotEmpty) {
      parts.add(address['name'].toString());
    }

    if (address['addressLine1'] != null &&
        address['addressLine1'].toString().isNotEmpty) {
      parts.add(address['addressLine1'].toString());
    }

    if (address['addressLine2'] != null &&
        address['addressLine2'].toString().isNotEmpty) {
      parts.add(address['addressLine2'].toString());
    }

    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city'].toString());
    }

    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      parts.add(address['state'].toString());
    }

    final pincode = address['pinCode'] ?? address['pincode'];
    if (pincode != null && pincode.toString().isNotEmpty) {
      parts.add(pincode.toString());
    }

    return parts.join(', ');
  }

  /// Extract tracking status for UI display
  static Map<String, dynamic> parseTrackingStatus(
      Map<String, dynamic> trackingData) {
    final status =
        trackingData['current_status']?.toString().toLowerCase() ?? 'unknown';

    // Map Delhivery statuses to user-friendly messages
    String displayStatus;
    String statusDescription;
    String statusColor;
    int progressLevel;

    switch (status) {
      case 'manifested':
      case 'manifest':
        displayStatus = 'Order Shipped';
        statusDescription = 'Your order has been dispatched and is on its way';
        statusColor = 'blue';
        progressLevel = 1;
        break;
      case 'in-transit':
      case 'in transit':
        displayStatus = 'In Transit';
        statusDescription = 'Your package is traveling to its destination';
        statusColor = 'orange';
        progressLevel = 2;
        break;
      case 'out-for-delivery':
      case 'out for delivery':
        displayStatus = 'Out for Delivery';
        statusDescription = 'Your package is out for delivery today';
        statusColor = 'green';
        progressLevel = 3;
        break;
      case 'delivered':
        displayStatus = 'Delivered';
        statusDescription = 'Your package has been successfully delivered';
        statusColor = 'success';
        progressLevel = 4;
        break;
      case 'exception':
      case 'delay':
        displayStatus = 'Delayed';
        statusDescription =
            'There is a delay in delivery. We apologize for the inconvenience';
        statusColor = 'warning';
        progressLevel = 2;
        break;
      case 'rto':
      case 'return':
        displayStatus = 'Returning';
        statusDescription = 'Package is being returned to sender';
        statusColor = 'danger';
        progressLevel = 1;
        break;
      default:
        displayStatus = 'Processing';
        statusDescription = 'Your order is being processed';
        statusColor = 'info';
        progressLevel = 0;
    }

    return {
      'display_status': displayStatus,
      'description': statusDescription,
      'color': statusColor,
      'progress_level': progressLevel,
      'original_status': status,
      'last_updated': trackingData['last_updated'],
      'estimated_delivery': trackingData['estimated_delivery'],
    };
  }

  /// Get tracking timeline for UI display
  static List<Map<String, dynamic>> formatTrackingTimeline(
      List<dynamic>? trackingHistory) {
    if (trackingHistory == null || trackingHistory.isEmpty) {
      return [];
    }

    return trackingHistory.map((scan) {
      final scanData = scan as Map<String, dynamic>;
      return {
        'date': scanData['date'],
        'status': scanData['status'] ?? scanData['description'],
        'location': scanData['location'] ?? '',
        'description': scanData['description'] ?? scanData['status'],
        'remarks': scanData['remarks'] ?? '',
        'formatted_date': _formatTrackingDate(scanData['date']),
        'icon': _getTrackingIcon(
            scanData['status']?.toString().toLowerCase() ?? ''),
      };
    }).toList();
  }

  /// Format tracking date for display
  static String _formatTrackingDate(dynamic dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateStr.toString();
    }
  }

  /// Get appropriate icon for tracking status
  static String _getTrackingIcon(String status) {
    switch (status) {
      case 'manifested':
      case 'manifest':
        return 'local_shipping';
      case 'in-transit':
      case 'in transit':
        return 'local_shipping';
      case 'out-for-delivery':
      case 'out for delivery':
        return 'delivery_dining';
      case 'delivered':
        return 'check_circle';
      case 'exception':
      case 'delay':
        return 'warning';
      case 'rto':
      case 'return':
        return 'undo';
      default:
        return 'info';
    }
  }

  /// Print authentication troubleshooting information
  static void printAuthTroubleshooting() {
    print('🔧 Enhanced Delhivery Authentication Troubleshooting:');
    print('');
    print('📋 Current Setup:');
    print('   Integration: Server-side via Firebase Functions');
    print(
        '   Address Handling: Structured fields (addressLine1, city, state, pinCode)');
    print('   Tracking: Real-time via API with waybill/order ID');
    print('   CORS: Resolved by server-side proxy');
    print('   Authentication: Managed server-side');
    print('');
    print('❌ If authentication is failing:');
    print('   1. Check Firebase Functions deployment');
    print('   2. Verify Delhivery token in Firebase Functions configuration');
    print('   3. Contact Delhivery for API access verification');
    print('   4. Check Firebase Functions logs for detailed errors');
    print('   5. Ensure structured address data is being passed correctly');
    print('');
    print('🚀 Deploy Functions:');
    print('   cd functions && firebase deploy --only functions');
    print('');
    print('🔍 Address Structure Required:');
    print('   - name: Customer name');
    print('   - addressLine1: Street address (required)');
    print('   - addressLine2: Apartment/building (optional)');
    print('   - city: City name (required)');
    print('   - state: State name (required)');
    print('   - pinCode: 6-digit PIN code (required)');
    print('   - phone: Contact number');
    print('');
    print('📞 Support:');
    print('   Delhivery: clientservice@delhivery.com');
    print('   Firebase: https://firebase.google.com/support');
  }
}
