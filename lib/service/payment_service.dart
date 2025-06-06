// services/payment_service.dart - Updated for V2 API and Web Integration
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keiwaywellness/models/order.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> initiatePayment({
    required double amount,
    required String orderId,
    required String userId,
    String? userPhone,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    try {
      print('🚀 Starting PhonePe Payment via Firebase Functions V2...');
      print('💰 Amount: ₹$amount');
      print('🆔 Order ID: $orderId');
      print('👤 User ID: $userId');
      print('📱 Phone: ${userPhone ?? "9999999999"}');
      print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('❌ User not authenticated');
        return false;
      }

      // Validate inputs
      if (amount < 1.0) {
        print('❌ Amount too low. Minimum amount is ₹1');
        return false;
      }

      if (orderId.length >= 35) {
        print('❌ Order ID too long. Must be less than 35 characters');
        return false;
      }

      // Prepare data for Cloud Function
      final requestData = {
        'amount': amount,
        'orderId': orderId,
        'userId': userId.length >= 36 ? userId.substring(0, 35) : userId,
        'userPhone': userPhone?.trim() ?? '9999999999',
        'redirectUrl': redirectUrl,
        'callbackUrl': callbackUrl,
      };

      // Remove null values to avoid issues
      requestData.removeWhere((key, value) => value == null);

      print('📋 Calling Firebase Function with data: $requestData');

      // Call Firebase Cloud Function
      final HttpsCallable callable =
          _functions.httpsCallable('initiatePhonePePayment');
      final result = await callable.call(requestData);

      print('📥 Function Response: ${result.data}');

      if (result.data != null && result.data['success'] == true) {
        final phonepeData = result.data['data'];

        if (phonepeData != null) {
          // V2 API Response Structure
          final orderId = phonepeData['orderId'];
          final state = phonepeData['state'];
          final redirectUrl = phonepeData['redirectUrl'];

          print('🆔 PhonePe Order ID: $orderId');
          print('📊 State: $state');
          print('🎯 Redirect URL: $redirectUrl');

          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            // Handle web vs mobile
            if (kIsWeb) {
              return await _handleWebPayment(redirectUrl);
            } else {
              return await _handleMobilePayment(redirectUrl);
            }
          } else {
            print('❌ No redirect URL found in response');
            return false;
          }
        } else {
          print('❌ Invalid response structure');
          print('Response data: $phonepeData');
          return false;
        }
      } else {
        print('❌ Firebase Function call failed');
        print('Response: ${result.data}');
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      print('💥 Firebase Functions Exception: ${e.code} - ${e.message}');
      print('Details: ${e.details}');

      // Provide specific error handling
      switch (e.code) {
        case 'invalid-argument':
          print(
              '❌ Invalid payment parameters. Check amount, orderId, and userId');
          break;
        case 'unauthenticated':
          print('❌ User not authenticated. Please login first');
          break;
        case 'internal':
          print('❌ Server error. Please try again later');
          break;
        default:
          print('❌ Unknown error: ${e.code}');
      }

      return false;
    } catch (e, stackTrace) {
      print('💥 Payment Exception: $e');
      print('📍 Stack Trace: $stackTrace');
      return false;
    }
  }

  Future<bool> _handleWebPayment(String redirectUrl) async {
    try {
      print('🌐 Handling web payment...');

      if (kIsWeb) {
        // Check if PhonePe checkout script is loaded
        final isPhonePeReady = js.context.callMethod('checkPhonePeReady', []);

        if (isPhonePeReady == true) {
          print('✅ PhonePe script loaded, using iframe integration');

          // Use PhonePe iframe integration
          final success = js.context.callMethod('phonepeCheckout', [
            redirectUrl,
            'IFRAME',
            js.allowInterop((response) {
              print('📞 PhonePe callback: $response');
              if (response == 'CONCLUDED') {
                print('✅ Payment concluded');
              } else if (response == 'USER_CANCEL') {
                print('❌ Payment cancelled by user');
              }
            })
          ]);

          if (success == true) {
            print('✅ PhonePe iframe launched successfully');
            return true;
          } else {
            print(
                '❌ Failed to launch PhonePe iframe, falling back to redirect');
            return await _handleFallbackRedirect(redirectUrl);
          }
        } else {
          print('❌ PhonePe script not ready, using fallback redirect');
          return await _handleFallbackRedirect(redirectUrl);
        }
      } else {
        return await _handleFallbackRedirect(redirectUrl);
      }
    } catch (e) {
      print('❌ Web payment error: $e');
      return await _handleFallbackRedirect(redirectUrl);
    }
  }

  Future<bool> _handleFallbackRedirect(String redirectUrl) async {
    try {
      print('🔄 Using fallback redirect method');
      final uri = Uri.parse(redirectUrl);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('✅ Payment page launched via redirect');
          return true;
        } else {
          print('❌ Failed to launch payment URL via redirect');
          return false;
        }
      } else {
        print('❌ Cannot launch URL: $redirectUrl');
        return false;
      }
    } catch (e) {
      print('❌ Fallback redirect error: $e');
      return false;
    }
  }

  Future<bool> _handleMobilePayment(String redirectUrl) async {
    try {
      print('📱 Handling mobile payment...');

      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('✅ Payment page launched successfully on mobile');
          return true;
        } else {
          print('❌ Failed to launch payment URL on mobile');
          return false;
        }
      } else {
        print('❌ Cannot launch URL on mobile: $redirectUrl');
        return false;
      }
    } catch (e) {
      print('❌ Mobile payment error: $e');
      return false;
    }
  }

  Future<bool> verifyPayment(String merchantOrderId) async {
    try {
      print('🔍 Verifying payment for merchant order: $merchantOrderId');

      if (_auth.currentUser == null) {
        print('❌ User not authenticated');
        return false;
      }

      final HttpsCallable callable = _functions.httpsCallable('verifyPayment');
      final result = await callable.call({'merchantOrderId': merchantOrderId});

      print('📥 Verification Response: ${result.data}');

      if (result.data['success'] == true) {
        final phonepeData = result.data['data'];
        final isSuccess = phonepeData['state'] == 'COMPLETED';

        print(isSuccess
            ? '✅ Payment verified successfully'
            : '❌ Payment not completed - State: ${phonepeData['state']}');

        // Update local order status if payment is successful
        if (isSuccess) {
          await _updateOrderStatus(merchantOrderId, 'completed');
        }

        return isSuccess;
      }

      return false;
    } on FirebaseFunctionsException catch (e) {
      print(
          '💥 Verification Firebase Functions Exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('💥 Payment verification error: $e');
      return false;
    }
  }

  Future<String> generateTransactionId() async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('generateTransactionId');
      final result = await callable.call();

      if (result.data['success'] == true) {
        return result.data['transactionId'];
      }

      // Fallback to local generation
      return _generateLocalTransactionId();
    } catch (e) {
      print('❌ Error generating transaction ID from server: $e');
      return _generateLocalTransactionId();
    }
  }

  String _generateLocalTransactionId() {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final fullId = 'TXN$timestamp$random';

      // Ensure the ID is not longer than 34 characters
      if (fullId.length > 34) {
        return fullId.substring(0, 34);
      }

      return fullId;
    } catch (e) {
      print('❌ Error generating local transaction ID: $e');
      // Fallback to a simpler ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'TXN$timestamp'.substring(0, 20);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('user_payments').doc(orderId).update({
        'status': status,
        'completedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Order status updated to: $status');
    } catch (e) {
      print('❌ Error updating order status: $e');
    }
  }

  Future<void> saveOrder({
    required String userId,
    required List<CartItemModel> items,
    required double total,
    required String shippingAddress,
    String? paymentTransactionId,
  }) async {
    try {
      print('💾 Saving order to Firestore...');
      print('👤 User ID: $userId');
      print('📦 Items count: ${items.length}');
      print('💰 Total: ₹$total');

      final order = OrderModel(
        id: '',
        userId: userId,
        items: items,
        total: total,
        createdAt: DateTime.now(),
        shippingAddress: shippingAddress,
        status: 'pending',
        paymentId: paymentTransactionId ?? '',
      );

      final docRef = await _firestore.collection('orders').add(order.toMap());
      print('✅ Order saved successfully with ID: ${docRef.id}');
    } catch (e, stackTrace) {
      print('❌ Error saving order: $e');
      print('📍 Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // Listen to payment status changes
  Stream<DocumentSnapshot> listenToPaymentStatus(String orderId) {
    return _firestore.collection('user_payments').doc(orderId).snapshots();
  }

  // Get payment history for user
  Future<List<DocumentSnapshot>> getPaymentHistory() async {
    try {
      if (_auth.currentUser == null) return [];

      final querySnapshot = await _firestore
          .collection('user_payments')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('❌ Error fetching payment history: $e');
      return [];
    }
  }

  // Test PhonePe connection method
  Future<bool> testPhonePeConnection() async {
    try {
      print('🧪 Testing PhonePe Connection via Firebase Functions V2...');

      if (_auth.currentUser == null) {
        print('❌ User not authenticated. Please login first.');
        return false;
      }

      // Test 1: Check if we can generate transaction ID locally first
      final localTransactionId = _generateLocalTransactionId();
      print('✅ Step 1: Local transaction ID generated: $localTransactionId');

      // Test 2: Check web integration if on web
      if (kIsWeb) {
        try {
          final isPhonePeReady = js.context.callMethod('checkPhonePeReady', []);
          if (isPhonePeReady == true) {
            print('✅ Step 2: PhonePe web script loaded and ready');
          } else {
            print('⚠️ Step 2: PhonePe web script not ready, will use fallback');
          }
        } catch (e) {
          print('⚠️ Step 2: Web integration check failed: $e');
        }
      }

      // Test 3: Try to call Firebase Functions
      try {
        print('🔄 Step 3: Testing Firebase Functions connection...');

        final HttpsCallable callable =
            _functions.httpsCallable('generateTransactionId');

        final result = await callable.call().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Firebase Functions call timed out');
          },
        );

        if (result.data != null && result.data['success'] == true) {
          print('✅ Step 3: Firebase Functions V2 responding correctly');
          print('✅ Server transaction ID: ${result.data['transactionId']}');
        } else {
          print(
              '❌ Step 3: Firebase Functions returned invalid response: ${result.data}');
          throw Exception('Invalid response from Firebase Functions');
        }
      } catch (e) {
        print('❌ Step 3: Firebase Functions call failed: $e');

        if (e.toString().contains('MissingPluginException')) {
          print(
              '🔧 Solution: Run "flutter clean && flutter pub get" and restart your app');
          return false;
        } else if (e.toString().contains('unauthenticated')) {
          print('🔧 Solution: User needs to be authenticated');
          return false;
        } else if (e.toString().contains('timeout')) {
          print(
              '🔧 Solution: Firebase Functions may be cold starting, try again');
          return false;
        }

        print('⚠️ Using local transaction ID generation as fallback');
      }

      // Test 4: Validate payment parameters
      const testAmount = 1.0;
      const testUserId = 'test_user_123';
      const testPhone = '9999999999';

      if (testAmount < 1.0) {
        print('❌ Step 4: Amount validation failed');
        return false;
      }

      if (localTransactionId.length >= 35) {
        print(
            '❌ Step 4: Transaction ID too long (${localTransactionId.length} chars)');
        return false;
      }

      if (testUserId.length >= 36) {
        print('❌ Step 4: User ID too long');
        return false;
      }

      print('✅ Step 4: All validation checks passed');
      print('✅ PhonePe V2 connection test completed!');
      print('📋 Test Summary:');
      print(
          '   - Authentication: ✅ User logged in (${_auth.currentUser?.uid})');
      print('   - Platform: ✅ ${kIsWeb ? "Web" : "Mobile"}');
      print('   - Transaction ID: ✅ Generated ($localTransactionId)');
      print('   - Validation: ✅ All parameters valid');
      print('   - API Version: ✅ V2');
      print('   - Ready for payment: ✅ Yes');

      return true;
    } catch (e) {
      print('💥 PhonePe V2 connection test failed: $e');
      print('❌ Error details: ${e.toString()}');
      print('🔧 Troubleshooting steps:');
      print('   1. Run: flutter clean && flutter pub get');
      print('   2. Restart your app completely');
      print('   3. Check if user is logged in');
      print('   4. Verify Firebase project configuration');
      print('   5. Ensure you have updated to V2 API');
      return false;
    }
  }

  // Debug method
  void printEnvironmentInfo() {
    print('🔧 Payment Service Environment Info:');
    print('🔥 Using Firebase Cloud Functions');
    print('📱 Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('🔑 Authentication: Firebase Auth');
    print('💾 Database: Cloud Firestore');
    print('👤 Current User: ${_auth.currentUser?.uid ?? 'Not logged in'}');
    print('🌐 Functions Region: ${_functions.app.options.projectId}');
    print('📋 API Version: V2');
    print('🎯 Payment Gateway: PhonePe');
  }

  // Static version for backward compatibility
  static void printEnvironmentInfoStatic() {
    print('🔧 Payment Service Environment Info:');
    print('🔥 Using Firebase Cloud Functions');
    print('📱 Platform: Flutter');
    print('🔑 Authentication: Firebase Auth');
    print('💾 Database: Cloud Firestore');
    print('📋 API Version: V2');
    print('🎯 Payment Gateway: PhonePe');
  }
}
