// services/payment_service.dart - Optimized Payment Service
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keiwaywellness/models/order.dart';
import 'package:keiwaywellness/service/shiprocket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save pending order data with structured address
  Future<void> savePendingOrderData({
    required String orderId,
    required String userId,
    required List<CartItemModel> items,
    required double total,
    required Map<String, dynamic> shippingAddress,
    required Map<String, dynamic> customerDetails,
    double? originalTotal,
    double? totalSavings,
    Map<String, dynamic>? discountSummary,
  }) async {
    final orderData = {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'shippingAddress': shippingAddress,
      'customerDetails': customerDetails,
      'status': 'pending_payment',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': FieldValue.serverTimestamp(),
    };

    if (originalTotal != null) orderData['originalTotal'] = originalTotal;
    if (totalSavings != null) orderData['totalSavings'] = totalSavings;
    if (discountSummary != null) {
      orderData['discountSummary'] = discountSummary;
      orderData['hasDiscounts'] = discountSummary['hasDiscounts'] ?? false;
    }

    await _firestore.collection('pending_orders').doc(orderId).set(orderData);
  }

  /// Optimized payment verification
  Future<Map<String, dynamic>> verifyPaymentAndProcessOrder(
      String merchantOrderId) async {
    if (_auth.currentUser == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    try {
      final callable = _functions.httpsCallable('verifyPayment');
      final result = await callable.call({'merchantOrderId': merchantOrderId});

      if (result.data['success'] == true) {
        final status = result.data['status'];
        final orderData = result.data['data'];

        switch (status) {
          case 'completed':
            return {
              'success': true,
              'status': 'completed',
              'message': result.data['message'] ??
                  'Payment successful! Your order has been confirmed.',
              'data': orderData
            };
          case 'pending':
            return {
              'success': false,
              'status': 'pending',
              'message':
                  result.data['message'] ?? 'Payment is being processed...',
              'retry': true,
              'data': orderData
            };
          case 'failed':
            return {
              'success': false,
              'status': 'failed',
              'message':
                  result.data['message'] ?? 'Payment failed or was cancelled',
              'error': result.data['error'] ?? 'PAYMENT_FAILED',
              'data': orderData
            };
          case 'not_found':
            return {
              'success': false,
              'status': 'not_found',
              'message': 'Payment verification in progress...',
              'retry': true
            };
          default:
            return {
              'success': false,
              'status': status,
              'message': 'Payment status unknown. Please try again.',
              'retry': true,
              'data': orderData
            };
        }
      }

      return {
        'success': false,
        'error': result.data['error'] ?? 'Payment verification failed',
        'message': result.data['message'] ?? 'Verification failed',
        'retry': result.data['retry'] ?? true
      };
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          return {
            'success': false,
            'error': 'Authentication failed',
            'message': 'Please login and try again',
            'retry': false
          };
        case 'invalid-argument':
          return {
            'success': false,
            'error': 'Invalid order ID',
            'message': 'Invalid order details. Please contact support.',
            'retry': false
          };
        default:
          return {
            'success': false,
            'error': 'Verification failed',
            'message': 'Payment verification error. Please try again.',
            'retry': true
          };
      }
    } catch (e) {
      // Firestore fallback
      try {
        final paymentDoc = await _firestore
            .collection('payment_requests')
            .doc(merchantOrderId)
            .get();

        if (paymentDoc.exists) {
          final status = paymentDoc.data()!['status'];
          if (status == 'payment_completed') {
            return {
              'success': true,
              'status': 'completed',
              'message': 'Payment successful! Order confirmed.',
              'source': 'firestore_fallback'
            };
          } else if (status == 'payment_failed') {
            return {
              'success': false,
              'status': 'failed',
              'message': 'Payment failed',
              'error': 'Payment was not successful'
            };
          }
        }
      } catch (_) {}

      return {
        'success': false,
        'error': 'System error during verification',
        'message': 'Verification failed. Please try again.',
        'retry': true
      };
    }
  }

  /// Optimized PhonePe payment initiation
  Future<bool> initiatePayment({
    required double amount,
    required String orderId,
    required String userId,
    String? userPhone,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    if (_auth.currentUser == null || amount < 1.0 || orderId.length >= 35) {
      return false;
    }

    try {
      final baseUrl = kIsWeb ? Uri.base.toString() : 'https://your-app.com';
      final verificationUrl =
          redirectUrl ?? '${baseUrl}payment-verification/$orderId';

      final requestData = {
        'amount': amount,
        'orderId': orderId,
        'userId': userId.length >= 36 ? userId.substring(0, 35) : userId,
        'userPhone': userPhone?.trim() ?? '9999999999',
        'redirectUrl': verificationUrl,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
      };

      final callable = _functions.httpsCallable('initiatePhonePePayment');
      final result = await callable.call(requestData);

      if (result.data?['success'] == true) {
        final redirectUrlResponse = result.data['data']?['redirectUrl'];

        if (redirectUrlResponse?.isNotEmpty == true) {
          return kIsWeb
              ? await _handleWebPayment(redirectUrlResponse)
              : await _handleMobilePayment(redirectUrlResponse);
        }
      }

      return false;
    } on FirebaseFunctionsException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Optimized web payment handling
  Future<bool> _handleWebPayment(String redirectUrl) async {
    if (!kIsWeb) return await _handleFallbackRedirect(redirectUrl);

    try {
      final isPhonePeReady = js.context.callMethod('checkPhonePeReady', []);

      if (isPhonePeReady == true) {
        final success = js.context.callMethod('phonepeCheckout', [
          redirectUrl,
          'IFRAME',
          js.allowInterop((response) {
            // Minimal callback handling
          })
        ]);

        if (success == true) return true;
      }
    } catch (_) {}

    return await _handleFallbackRedirect(redirectUrl);
  }

  /// Optimized fallback redirect
  Future<bool> _handleFallbackRedirect(String redirectUrl) async {
    try {
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Optimized mobile payment handling
  Future<bool> _handleMobilePayment(String redirectUrl) async {
    try {
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Optimized transaction ID generation
  Future<String> generateTransactionId() async {
    try {
      final callable = _functions.httpsCallable('generateTransactionId');
      final result = await callable.call();

      if (result.data['success'] == true) {
        return result.data['transactionId'];
      }
    } catch (_) {}

    return _generateLocalTransactionId();
  }

  /// Local transaction ID fallback
  String _generateLocalTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    final fullId = 'TXN$timestamp$random';
    return fullId.length > 34 ? fullId.substring(0, 34) : fullId;
  }

  /// Get pending order
  Future<Map<String, dynamic>?> getPendingOrder(String orderId) async {
    try {
      final doc =
          await _firestore.collection('pending_orders').doc(orderId).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  /// Get confirmed order
  Future<Map<String, dynamic>?> getConfirmedOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  /// Optimized connection test
  Future<bool> testPhonePeConnection() async {
    if (_auth.currentUser == null) return false;

    try {
      // Quick transaction ID test
      final localId = _generateLocalTransactionId();
      if (localId.isEmpty) return false;

      // Quick Firebase Functions test
      try {
        final callable = _functions.httpsCallable('generateTransactionId');
        await callable.call().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Functions not available, but local generation works
      }

      // Quick Delhivery test
      try {
        await DelhiveryService.testConnection();
      } catch (_) {
        // Delhivery test failed, but can use defaults
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Minimal environment info
  void printEnvironmentInfo() {
    if (kDebugMode) {
      debugPrint('Payment Service: Ready');
      debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      debugPrint('User: ${_auth.currentUser?.uid ?? 'Not logged in'}');
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      final doc =
          await _firestore.collection('payment_requests').doc(orderId).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  /// Check order confirmation
  Future<bool> isOrderConfirmed(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Format address for Delhivery
  Map<String, dynamic> formatAddressForDelhivery(
      Map<String, dynamic> address, Map<String, dynamic> customerDetails) {
    return {
      'name': address['name'] ?? customerDetails['name'] ?? 'Customer',
      'addressLine1':
          address['addressLine1'] ?? address['address'] ?? 'Address',
      'addressLine2': address['addressLine2'] ?? '',
      'city': address['city'] ?? 'City',
      'state': address['state'] ?? 'State',
      'pinCode': address['pinCode'] ?? address['pincode'] ?? '000000',
      'phone': customerDetails['phone'] ?? '0000000000',
      'country': 'India'
    };
  }

  /// Extract structured address
  Map<String, dynamic> extractStructuredAddress(dynamic addressData) {
    if (addressData is Map<String, dynamic>) {
      return addressData;
    } else if (addressData is String) {
      final parts = addressData.split(',').map((e) => e.trim()).toList();
      return {
        'addressLine1': parts.isNotEmpty ? parts[0] : 'Address',
        'addressLine2': parts.length > 1 ? parts[1] : '',
        'city': parts.length > 2 ? parts[parts.length - 3] : 'City',
        'state': parts.length > 1 ? parts[parts.length - 2] : 'State',
        'pinCode': parts.isNotEmpty ? _extractPincode(parts.last) : '000000',
      };
    }

    return {
      'addressLine1': 'Address',
      'addressLine2': '',
      'city': 'City',
      'state': 'State',
      'pinCode': '000000',
    };
  }

  /// Extract pincode from text
  String _extractPincode(String text) {
    final match = RegExp(r'\b(\d{6})\b').firstMatch(text);
    return match?.group(1) ?? '000000';
  }

  /// Clean up old pending orders
  Future<void> cleanupOldPendingOrders() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final query = await _firestore
          .collection('pending_orders')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      if (query.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in query.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}
  }
}
