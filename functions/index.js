// functions/index.js - Updated with discount support in order processing
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const crypto = require("crypto");

admin.initializeApp();

// PhonePe V2 Configuration
const PHONEPE_CONFIG = {
  merchantId: "PGTESTPAYUAT",
  saltKey: "099eb0cd-02cf-4e2a-8aca-3e6c6aff0399",
  saltIndex: "1",
  baseUrl: "https://api-preprod.phonepe.com/apis/pg-sandbox",
  clientId: "TEST-M23675ZMAG3KW_25052",
  clientSecret: "MGJjNDJlYjMtODMzZS00OGJiLTkwY2QtNzY1YzFiZDNmNTli",
};

// Delhivery Configuration
const DELHIVERY_CONFIG = {
  token: '68743057c62717b9f0c08fa3f3d25f25cde9cb8a',
  clientName: 'keiway-wellness',
  baseUrl: 'https://track.delhivery.com',
  defaults: {
    pickup_location: {
      name: "Ayush kumar",
      add: "N-1/8 gka dalmia kothi lane 1",
      city: "Varanasi",
      pin_code: 221005,
      country: "India",
      phone: "7800119990"
    },
    customer: {
      name: "Anushka shahi",
      add: "New Abadi, Street No 18",
      pin: "335513",
      city: "Hanumangarh Town",
      state: "Rajasthan",
      country: "India",
      phone: "7800119990"
    },
    business: {
      seller_name: "Keiway Wellness Store",
      seller_add: "New Abadi, Street No 18, Hanumangarh Town, Rajasthan - 335513",
      seller_gst_tin: "08ABCDE1234F2Z5",
      seller_inv: "KW",
    }
  }
};

// Helper function to get safe default values
function getSafeShippingData(customerDetails, shippingAddress) {
  const defaults = DELHIVERY_CONFIG.defaults;
  
  const safeName = (customerDetails?.name && customerDetails.name.trim() !== '') 
    ? `${customerDetails.name} ${customerDetails.lastName || ''}`.trim()
    : defaults.customer.name;
    
  const safeAddress = (shippingAddress?.address && shippingAddress.address.trim() !== '')
    ? shippingAddress.address
    : defaults.customer.add;
    
  const safeCity = (shippingAddress?.city && shippingAddress.city.trim() !== '')
    ? shippingAddress.city
    : defaults.customer.city;
    
  const safeState = (shippingAddress?.state && shippingAddress.state.trim() !== '')
    ? shippingAddress.state
    : defaults.customer.state;
    
  const safePincode = (shippingAddress?.pincode && 
                      shippingAddress.pincode.length === 6 && 
                      shippingAddress.pincode !== '000000')
    ? shippingAddress.pincode
    : defaults.customer.pin;
    
  const safePhone = (customerDetails?.phone && customerDetails.phone.trim() !== '')
    ? customerDetails.phone.toString()
    : defaults.customer.phone;
    
  const safeEmail = (customerDetails?.email && customerDetails.email.trim() !== '')
    ? customerDetails.email
    : 'customer@example.com';

  return {
    name: safeName,
    address: safeAddress,
    city: safeCity,
    state: safeState,
    pincode: safePincode,
    phone: safePhone,
    email: safeEmail,
    country: 'India'
  };
}

// PhonePe Auth Token Function
async function getAuthToken() {
  try {
    console.log("🔑 Getting PhonePe auth token...");
    
    const response = await axios.post(
      `${PHONEPE_CONFIG.baseUrl}/v1/oauth/token`,
      new URLSearchParams({
        client_id: PHONEPE_CONFIG.clientId,
        client_version: "1",
        client_secret: PHONEPE_CONFIG.clientSecret,
        grant_type: "client_credentials",
      }),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        timeout: 10000,
      }
    );

    console.log("✅ Auth token obtained successfully");
    return response.data.access_token;
  } catch (error) {
    console.error("❌ Auth token error:", error.response?.data || error.message);
    throw new Error(`Failed to get auth token: ${error.response?.data?.message || error.message}`);
  }
}

// Generate transaction ID
function generateTransactionId() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, "0");
  return `TXN${timestamp}${random}`.substring(0, 34);
}

// Initialize PhonePe Payment
exports.initiatePhonePePayment = functions.https.onCall(async (data, context) => {
  try {
    console.log("🚀 Initiating PhonePe Payment with V2 API (Payment-First Flow)...");

    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { amount, orderId, userId, userPhone, redirectUrl } = data;

    if (!amount || !orderId || !userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: amount, orderId, userId"
      );
    }

    const amountInPaisa = Math.round(amount * 100);
    if (amountInPaisa < 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Amount too low. Minimum amount is ₹1"
      );
    }

    const accessToken = await getAuthToken();

    const paymentData = {
      merchantOrderId: orderId,
      amount: amountInPaisa,
      expireAfter: 1200,
      metaInfo: {
        udf1: userId,
        udf2: userPhone || "9999999999",
        udf3: "Payment-First Flow",
        udf4: "Delhivery Shipping",
        udf5: "V2",
      },
      paymentFlow: {
        type: "PG_CHECKOUT",
        message: "Complete payment to confirm order",
        merchantUrls: {
          redirectUrl: redirectUrl || `https://${context.rawRequest.headers.host}/payment-verification/${orderId}`,
        },
      },
    };

    console.log("📋 V2 Payment Payload:", JSON.stringify(paymentData, null, 2));

    const response = await axios.post(
      `${PHONEPE_CONFIG.baseUrl}/checkout/v2/pay`,
      paymentData,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `O-Bearer ${accessToken}`,
        },
        timeout: 15000,
      }
    );

    console.log("✅ PhonePe V2 Response:", response.data);

    // Save payment request
    await admin.firestore().collection("payment_requests").doc(orderId).set({
      userId: context.auth.uid,
      orderId: orderId,
      amount: amount,
      amountInPaisa: amountInPaisa,
      status: "payment_initiated",
      phonepeResponse: response.data,
      flow: "payment_first",
      shippingPartner: "delhivery",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("💾 Payment request saved");

    return {
      success: true,
      data: response.data,
      flow: "payment_first",
      message: "Payment initiated - order will be confirmed after payment success"
    };
  } catch (error) {
    console.error("❌ PhonePe V2 API Error:", error.response?.data || error.message);

    if (data.orderId) {
      await admin.firestore().collection("payment_errors").add({
        orderId: data.orderId,
        error: error.response?.data || error.message,
        flow: "payment_first",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (error.response?.status === 401) {
      throw new functions.https.HttpsError("unauthenticated", "PhonePe authentication failed");
    } else if (error.response?.status === 400) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid payment parameters");
    }

    throw new functions.https.HttpsError("internal", "Payment initiation failed");
  }
});

// Verify Payment using PhonePe Order Status API
exports.verifyPayment = functions.https.onCall(async (data, context) => {
  try {
    console.log("🔍 Verifying payment with PhonePe Order Status API...");

    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { merchantOrderId } = data;

    if (!merchantOrderId) {
      throw new functions.https.HttpsError("invalid-argument", "Merchant Order ID is required");
    }

    console.log(`🔍 Checking payment status for order: ${merchantOrderId}`);

    const accessToken = await getAuthToken();
    const statusUrl = `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/${merchantOrderId}/status?details=true&errorContext=true`;
    
    console.log(`📡 Calling PhonePe Order Status API: ${statusUrl}`);

    const response = await axios.get(statusUrl, {
      headers: {
        "Content-Type": "application/json",
        "Authorization": `O-Bearer ${accessToken}`,
      },
      timeout: 15000,
    });

    console.log("✅ PhonePe Order Status Response:", JSON.stringify(response.data, null, 2));

    const paymentRef = admin.firestore().collection("payment_requests").doc(merchantOrderId);
    await paymentRef.update({
      verificationResponse: response.data,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastVerificationAttempt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const orderData = response.data;
    const orderState = orderData.state;
    
    console.log(`📊 Order State: ${orderState}`);

    if (orderState === "COMPLETED") {
      console.log("💰 Payment COMPLETED - Processing order...");
      
      await paymentRef.update({
        status: "payment_completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      try {
        await processSuccessfulPayment(merchantOrderId, orderData);
        
        return {
          success: true,
          status: "completed",
          data: orderData,
          message: "Payment successful! Your order has been confirmed and will be shipped."
        };
      } catch (orderProcessingError) {
        console.error("❌ Order processing error:", orderProcessingError);
        
        return {
          success: true,
          status: "completed",
          data: orderData,
          message: "Payment successful! Order confirmation in progress.",
          warning: "Order processing delayed but payment completed"
        };
      }
      
    } else if (orderState === "PENDING") {
      console.log("⏳ Payment PENDING - Continue verification...");
      
      await paymentRef.update({
        status: "payment_pending"
      });

      return {
        success: false,
        status: "pending",
        data: orderData,
        message: "Payment is still being processed. Please wait...",
        retry: true
      };
      
    } else if (orderState === "FAILED") {
      console.log("❌ Payment FAILED");
      
      await paymentRef.update({
        status: "payment_failed",
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        failureReason: orderData.errorCode || "Payment failed"
      });

      let errorMessage = "Payment failed";
      if (orderData.errorContext) {
        errorMessage = orderData.errorContext.description || errorMessage;
      }

      return {
        success: false,
        status: "failed",
        data: orderData,
        message: errorMessage,
        error: orderData.errorCode || "PAYMENT_FAILED"
      };
      
    } else {
      console.log(`⚠️ Unknown payment state: ${orderState}`);
      
      return {
        success: false,
        status: orderState?.toLowerCase() || "unknown",
        data: orderData,
        message: `Payment status: ${orderState}. Please try again or contact support.`,
        retry: true
      };
    }

  } catch (error) {
    console.error("❌ Payment verification error:", error.response?.data || error.message);

    if (error.response?.status === 404) {
      console.log("⚠️ Order not found in PhonePe - might be too early or invalid order ID");
      return {
        success: false,
        status: "not_found",
        message: "Payment verification in progress. Please wait and try again.",
        retry: true,
        error: "ORDER_NOT_FOUND"
      };
    }

    if (error.response?.status === 401) {
      throw new functions.https.HttpsError("unauthenticated", "PhonePe authentication failed");
    }

    await admin.firestore().collection("verification_errors").add({
      orderId: data.merchantOrderId,
      error: error.response?.data || error.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    throw new functions.https.HttpsError("internal", "Payment verification failed. Please try again.");
  }
});

// Process successful payment and create order with discount support
async function processSuccessfulPayment(merchantOrderId, paymentData) {
  try {
    console.log(`✅ Processing successful payment for order: ${merchantOrderId}`);

    const pendingOrderDoc = await admin.firestore().collection("pending_orders").doc(merchantOrderId).get();

    if (!pendingOrderDoc.exists) {
      throw new Error(`Pending order not found for ID: ${merchantOrderId}`);
    }

    const pendingData = pendingOrderDoc.data();
    console.log("📋 Found pending order data");

    // Calculate discount summary from cart items
    let originalTotal = 0;
    let discountedTotal = 0;
    let totalSavings = 0;
    const discountDetails = [];

    if (pendingData.items && Array.isArray(pendingData.items)) {
      pendingData.items.forEach(item => {
        const itemOriginalPrice = item.originalPrice || item.price;
        const itemCurrentPrice = item.price;
        const itemQuantity = item.quantity || 1;
        
        const itemOriginalTotal = itemOriginalPrice * itemQuantity;
        const itemDiscountedTotal = itemCurrentPrice * itemQuantity;
        const itemSavings = itemOriginalTotal - itemDiscountedTotal;
        
        originalTotal += itemOriginalTotal;
        discountedTotal += itemDiscountedTotal;
        totalSavings += itemSavings;

        if (itemSavings > 0) {
          const discountPercentage = ((itemSavings / itemOriginalTotal) * 100).toFixed(1);
          discountDetails.push({
            productName: item.name,
            originalPrice: itemOriginalPrice,
            discountedPrice: itemCurrentPrice,
            quantity: itemQuantity,
            savingsAmount: itemSavings,
            discountPercentage: parseFloat(discountPercentage)
          });
        }
      });
    }

    // Create confirmed order with discount information
    const confirmedOrder = {
      id: merchantOrderId,
      userId: pendingData.userId,
      items: pendingData.items,
      total: pendingData.total,
      originalTotal: originalTotal,
      totalSavings: totalSavings,
      discountDetails: discountDetails,
      hasDiscounts: totalSavings > 0,
      shippingAddress: pendingData.shippingAddress,
      customerDetails: pendingData.customerDetails,
      status: "confirmed",
      paymentStatus: "completed",
      paymentId: merchantOrderId,
      paymentData: paymentData,
      paymentCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Save confirmed order
    await admin.firestore().collection("orders").doc(merchantOrderId).set(confirmedOrder);
    console.log("✅ Confirmed order created with discount tracking");

    // Create Delhivery shipping order
    try {
      console.log("📦 Creating Delhivery shipping order...");
      
      const customerDetails = pendingData.customerDetails;
      const shippingAddress = pendingData.shippingAddress;

      const addressParts = shippingAddress.split(',').map(part => part.trim());
      const pincodeMatch = shippingAddress.match(/\b(\d{6})\b/);
      const stateMatch = shippingAddress.match(/([A-Za-z\s]+)\s*-?\s*\d{6}/);

      const parsedAddress = {
        address: addressParts[0] || 'New Abadi, Street No 18',
        city: addressParts.length > 2 ? addressParts[addressParts.length - 3] : 'Hanumangarh Town',
        state: stateMatch ? stateMatch[1].trim() : 'Rajasthan',
        pincode: pincodeMatch ? pincodeMatch[1] : '335513'
      };

      const safeData = getSafeShippingData(customerDetails, parsedAddress);

      const itemCount = pendingData.items ? pendingData.items.length : 1;
      const packageWeight = Math.max(0.5, itemCount * 0.3);
      const packageDimensions = { length: 15, breadth: 15, height: 10 };

      // Prepare products description with discount info
      let productsDesc = "Wellness Products";
      let quantity = "1";
      
      if (pendingData.items && Array.isArray(pendingData.items) && pendingData.items.length > 0) {
        productsDesc = pendingData.items.map(item => {
          let itemDesc = `${item.name || 'Product'} (Qty: ${item.quantity || 1})`;
          if (item.originalPrice && item.price < item.originalPrice) {
            const savings = ((item.originalPrice - item.price) / item.originalPrice * 100).toFixed(0);
            itemDesc += ` [${savings}% OFF]`;
          }
          return itemDesc;
        }).join(', ');
        quantity = pendingData.items.reduce((sum, item) => sum + (item.quantity || 1), 0).toString();
      }

      const shipmentData = {
        name: safeData.name,
        add: safeData.address,
        pin: safeData.pincode,
        city: safeData.city,
        state: safeData.state,
        country: safeData.country,
        phone: safeData.phone,
        order: merchantOrderId,
        payment_mode: 'Prepaid',
        return_pin: DELHIVERY_CONFIG.defaults.pickup_location.pin_code.toString(),
        return_city: DELHIVERY_CONFIG.defaults.pickup_location.city,
        return_phone: DELHIVERY_CONFIG.defaults.pickup_location.phone,
        return_add: DELHIVERY_CONFIG.defaults.pickup_location.add,
        return_state: "Uttar Pradesh",
        return_country: "India",
        products_desc: productsDesc,
        hsn_code: "30049099",
        cod_amount: "0",
        order_date: new Date().toISOString(),
        total_amount: pendingData.total.toString(),
        seller_add: DELHIVERY_CONFIG.defaults.business.seller_add,
        seller_name: DELHIVERY_CONFIG.defaults.business.seller_name,
        seller_inv: DELHIVERY_CONFIG.defaults.business.seller_inv,
        quantity: quantity,
        waybill: "",
        shipment_width: packageDimensions.breadth.toString(),
        shipment_height: packageDimensions.height.toString(),
        weight: packageWeight.toString(),
        seller_gst_tin: DELHIVERY_CONFIG.defaults.business.seller_gst_tin,
        shipping_mode: "Surface",
        address_type: "home",
        email: safeData.email,
      };

      const delhiveryOrderData = {
        shipments: [shipmentData],
        pickup_location: DELHIVERY_CONFIG.defaults.pickup_location
      };

      const url = `${DELHIVERY_CONFIG.baseUrl}/api/cmu/create.json`;
      const requestData = `format=json&data=${JSON.stringify(delhiveryOrderData)}`;
      
      const delhiveryResponse = await axios.post(url, requestData, {
        headers: {
          'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        timeout: 15000,
      });

      console.log("📦 Delhivery API Response:", delhiveryResponse.status, delhiveryResponse.data);

      if (delhiveryResponse.status === 200) {
        const delhiveryData = delhiveryResponse.data;
        const isSuccess = delhiveryData.success === true || 
                       delhiveryData.rmk === 'Success' || 
                       delhiveryData.packages ||
                       (delhiveryData && !delhiveryData.error);

        if (isSuccess) {
          let assignedWaybill = null;
          let trackingUrl = null;
          
          if (delhiveryData.packages && delhiveryData.packages.length > 0) {
            assignedWaybill = delhiveryData.packages[0].waybill;
            trackingUrl = `${DELHIVERY_CONFIG.baseUrl}/api/v1/packages/json/?waybill=${assignedWaybill}`;
          }

          await admin.firestore().collection('orders').doc(merchantOrderId).update({
            delhivery: {
              waybill: assignedWaybill,
              status: 'Manifested',
              tracking_url: trackingUrl,
              payment_mode: 'Prepaid',
              used_defaults: safeData.pincode === DELHIVERY_CONFIG.defaults.customer.pin,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              response: delhiveryData
            },
            shippingStatus: 'manifested',
            shippingPartner: 'delhivery',
            status: 'processing',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log("✅ Delhivery order created and order updated");
        } else {
          throw new Error(`Delhivery order creation failed: ${delhiveryData.rmk || delhiveryData.error || 'Unknown error'}`);
        }
      } else {
        throw new Error(`Delhivery API error: ${delhiveryResponse.status}`);
      }

    } catch (delhiveryError) {
      console.error("⚠️ Delhivery order creation failed:", delhiveryError.message);
      
      await admin.firestore().collection('orders').doc(merchantOrderId).update({
        delhiveryError: delhiveryError.message,
        delhiveryRetryNeeded: true,
        shippingPartner: 'delhivery',
        note: 'Payment successful, order confirmed, but shipping setup failed - will retry',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await admin.firestore().collection("pending_orders").doc(merchantOrderId).delete();
    console.log("🗑️ Pending order cleaned up");

    console.log(`✅ Payment processing completed successfully for order ${merchantOrderId}`);

  } catch (error) {
    console.error("❌ Error processing successful payment:", error);
    throw error;
  }
}

// Generate transaction ID
exports.generateTransactionId = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const transactionId = generateTransactionId();

  await admin.firestore().collection("transaction_logs").add({
    userId: context.auth.uid,
    transactionId: transactionId,
    flow: "payment_first",
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    transactionId: transactionId,
    flow: "payment_first"
  };
});

// Webhook handler for payment status updates
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  try {
    console.log("📞 PhonePe payment webhook received:", req.body);

    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ success: false, error: "Missing authorization" });
    }

    const event = req.body.event;
    const payload = req.body.payload;

    if (!event || !payload) {
      return res.status(400).json({ success: false, error: "Invalid webhook data" });
    }

    const merchantOrderId = payload.merchantOrderId;
    if (merchantOrderId) {
      let status = "payment_pending";
      
      if (event === "checkout.order.completed" && payload.state === "COMPLETED") {
        status = "payment_completed";
        
        try {
          await processSuccessfulPayment(merchantOrderId, payload);
          console.log(`✅ Webhook processed successful payment: ${merchantOrderId}`);
        } catch (processError) {
          console.error("❌ Webhook order processing error:", processError);
        }
        
      } else if (event === "checkout.order.failed" && payload.state === "FAILED") {
        status = "payment_failed";
      }

      await admin.firestore().collection("payment_requests").doc(merchantOrderId).update({
        webhookResponse: req.body,
        status: status,
        webhookReceivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Webhook processed: ${merchantOrderId} status updated to ${status}`);
    }

    res.status(200).json({ success: true });
  } catch (error) {
    console.error("❌ Webhook error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Health check
exports.healthCheck = functions.https.onRequest(async (req, res) => {
  try {
    const accessToken = await getAuthToken();
    
    res.json({
      success: true,
      status: "healthy",
      services: {
        phonepe: "connected",
        delhivery: "server_side_integrated",
        firestore: "connected"
      },
      apis: {
        "phonepe_order_status": `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/{merchantOrderId}/status`,
        "phonepe_payment": `${PHONEPE_CONFIG.baseUrl}/checkout/v2/pay`
      },
      flow: "payment_first",
      timestamp: new Date().toISOString(),
      version: "2.5.0",
      verification_method: "PhonePe Order Status API",
      working_pincode: DELHIVERY_CONFIG.defaults.customer.pin,
      features: ["discount_tracking", "order_discount_summary"],
      message: "Payment verification with discount support and order tracking"
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      status: "unhealthy",
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Keep existing functions...
exports.checkDelhiveryServiceability = functions.https.onCall(async (data, context) => {
  try {
    console.log('🔍 Checking Delhivery serviceability...');

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pincode } = data;

    if (!pincode || pincode.length !== 6) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid 6-digit pincode is required');
    }

    const url = `${DELHIVERY_CONFIG.baseUrl}/c/api/pin-codes/json/?filter_codes=${pincode}`;
    
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      timeout: 10000,
    });

    if (response.status === 200) {
      const data = response.data;
      
      if (data.delivery_codes && data.delivery_codes.length > 0) {
        const pincodeData = data.delivery_codes[0];
        
        return {
          success: true,
          serviceable: true,
          pincode: pincodeData.postal_code,
          city: pincodeData.district,
          state: pincodeData.state_code,
          cod_available: pincodeData.cod === 'Y',
          prepaid_available: pincodeData.pre_paid === 'Y',
          cash_available: pincodeData.cash === 'Y',
          pickup_available: pincodeData.pickup === 'Y',
          repl_available: pincodeData.repl === 'Y',
        };
      } else {
        return {
          success: true,
          serviceable: false,
          message: 'Pincode not serviceable by Delhivery',
          pincode: pincode,
        };
      }
    } else {
      throw new Error(`Delhivery API returned status: ${response.status}`);
    }
  } catch (error) {
    console.error('❌ Delhivery serviceability check error:', error.response?.data || error.message);
    throw new functions.https.HttpsError('internal', 'Serviceability check failed');
  }
});

// Clean up old logs
exports.cleanupTransactionLogs = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 30);

  try {
    const transactionQuery = admin.firestore()
      .collection('transaction_logs')
      .where('generatedAt', '<', cutoffDate)
      .limit(500);

    const transactionSnapshot = await transactionQuery.get();
    
    if (!transactionSnapshot.empty) {
      const batch = admin.firestore().batch();
      transactionSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Cleaned up ${transactionSnapshot.size} old transaction logs`);
    }

    const pendingQuery = admin.firestore()
      .collection('pending_orders')
      .where('createdAt', '<', cutoffDate)
      .limit(500);

    const pendingSnapshot = await pendingQuery.get();
    
    if (!pendingSnapshot.empty) {
      const batch = admin.firestore().batch();
      pendingSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Cleaned up ${pendingSnapshot.size} old pending orders`);
    }

    const errorQuery = admin.firestore()
      .collection('verification_errors')
      .where('timestamp', '<', cutoffDate)
      .limit(500);

    const errorSnapshot = await errorQuery.get();
    
    if (!errorSnapshot.empty) {
      const batch = admin.firestore().batch();
      errorSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Cleaned up ${errorSnapshot.size} old verification errors`);
    }

    console.log('✅ PhonePe payment verification cleanup completed');
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
});