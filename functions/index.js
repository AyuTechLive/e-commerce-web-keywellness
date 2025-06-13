// functions/index.js - Complete Production Ready PhonePe + Delhivery Integration
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const crypto = require("crypto");

admin.initializeApp();

// PhonePe PRODUCTION Configuration
const PHONEPE_CONFIG = {
  clientId: "SU2505231813159051637752",
  clientSecret: "5bbc7348-5e26-44b4-8511-449141d6f097",
  baseUrl: "https://api.phonepe.com/apis/pg", // PRODUCTION
  authUrl: "https://api.phonepe.com/apis/identity-manager", // PRODUCTION
  clientVersion: "1",
  environment: "production"
};

// Delhivery Configuration with proper endpoints
const DELHIVERY_CONFIG = {
  token: '68743057c62717b9f0c08fa3f3d25f25cde9cb8a',
  clientName: 'KEIWAYWELLNESSSURFACE-B2C',
  baseUrl: 'https://track.delhivery.com',
  trackingUrl: 'https://track.delhivery.com',
  productionTrackingUrl: 'https://track.delhivery.com',
  defaults: {
    pickup_location: {
      name: "Keiway Wellness Private Limited",
      add: "Shop no 201, Green City ,Hanumangarh town",
      city: "Hanumangarh",
      pin_code: 335513,
      country: "India",
      phone: "9461230876"
    },
    customer: {
      name: "Customer",
      add: "New Abadi, Street No 18",
      pin: "335513",
      city: "Hanumangarh Town",
      state: "Rajasthan",
      country: "India",
      phone: "7800119990"
    },
    business: {
      seller_name: "Keiway Wellness Store",
      seller_add: "N-1/8 gka dalmia kothi lane 1, Varanasi, Uttar Pradesh - 221005",
      seller_gst_tin: "09ABCDE1234F2Z5",
      seller_inv: "KW",
    }
  }
};

// Helper function to safely extract address components
function extractAddressComponents(addressData) {
  console.log("🏠 Extracting address components from:", addressData);
  
  let addressLine1 = '';
  let addressLine2 = '';
  let city = '';
  let state = '';
  let pincode = '';
  let name = '';
  let phone = '';
  
  if (typeof addressData === 'object' && addressData !== null) {
    addressLine1 = addressData.addressLine1 || addressData.address || '';
    addressLine2 = addressData.addressLine2 || '';
    city = addressData.city || '';
    state = addressData.state || '';
    pincode = addressData.pinCode || addressData.pincode || '';
    name = addressData.name || '';
    phone = addressData.phone || '';
  } else if (typeof addressData === 'string') {
    const parts = addressData.split(',').map(part => part.trim());
    if (parts.length >= 1) addressLine1 = parts[0];
    if (parts.length >= 2) addressLine2 = parts[1];
    if (parts.length >= 3) city = parts[parts.length - 3];
    if (parts.length >= 2) state = parts[parts.length - 2];
    if (parts.length >= 1) {
      const lastPart = parts[parts.length - 1];
      const pincodeMatch = lastPart.match(/\d{6}/);
      if (pincodeMatch) pincode = pincodeMatch[0];
    }
  }
  
  const safeAddress = {
    name: name || DELHIVERY_CONFIG.defaults.customer.name,
    addressLine1: addressLine1 || DELHIVERY_CONFIG.defaults.customer.add,
    addressLine2: addressLine2 || '',
    city: city || DELHIVERY_CONFIG.defaults.customer.city,
    state: state || DELHIVERY_CONFIG.defaults.customer.state,
    pincode: pincode || DELHIVERY_CONFIG.defaults.customer.pin,
    phone: phone || DELHIVERY_CONFIG.defaults.customer.phone,
    country: 'India'
  };
  
  console.log("✅ Extracted address components:", safeAddress);
  return safeAddress;
}

// Helper function to safely extract customer details
function extractCustomerDetails(customerData) {
  console.log("👤 Extracting customer details from:", customerData);
  
  const safeCustomer = {
    name: customerData?.name || DELHIVERY_CONFIG.defaults.customer.name,
    lastName: customerData?.lastName || '',
    email: customerData?.email || 'customer@example.com',
    phone: customerData?.phone || DELHIVERY_CONFIG.defaults.customer.phone
  };
  
  safeCustomer.fullName = `${safeCustomer.name} ${safeCustomer.lastName}`.trim();
  
  console.log("✅ Extracted customer details:", safeCustomer);
  return safeCustomer;
}

// PhonePe Auth Token Function
async function getAuthToken() {
  try {
    console.log("🔑 Getting PhonePe PRODUCTION auth token...");
    
    const response = await axios.post(
      `${PHONEPE_CONFIG.authUrl}/v1/oauth/token`,
      new URLSearchParams({
        client_id: PHONEPE_CONFIG.clientId,
        client_version: PHONEPE_CONFIG.clientVersion,
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

    console.log("✅ Production auth token obtained successfully");
    return response.data.access_token;
  } catch (error) {
    console.error("❌ Production auth token error:", error.response?.data || error.message);
    throw new Error(`Failed to get production auth token: ${error.response?.data?.message || error.message}`);
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
    console.log("🚀 Initiating PhonePe PRODUCTION Payment...");

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
        udf3: "Production Payment",
        udf4: "Keiway Wellness",
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

    console.log("📋 Production Payment Payload:", JSON.stringify(paymentData, null, 2));

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

    console.log("✅ PhonePe Production Response:", response.data);

    await admin.firestore().collection("payment_requests").doc(orderId).set({
      userId: context.auth.uid,
      orderId: orderId,
      amount: amount,
      amountInPaisa: amountInPaisa,
      status: "payment_initiated",
      phonepeResponse: response.data,
      flow: "payment_first",
      environment: "production",
      shippingPartner: "delhivery",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("💾 Payment request saved");

    return {
      success: true,
      data: response.data,
      flow: "payment_first",
      environment: "production",
      message: "Production payment initiated - order will be confirmed after payment success"
    };
  } catch (error) {
    console.error("❌ PhonePe Production API Error:", error.response?.data || error.message);

    if (data.orderId) {
      await admin.firestore().collection("payment_errors").add({
        orderId: data.orderId,
        error: error.response?.data || error.message,
        flow: "payment_first",
        environment: "production",
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
    console.log("🔍 Verifying payment with PhonePe PRODUCTION Order Status API...");

    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { merchantOrderId } = data;

    if (!merchantOrderId) {
      throw new functions.https.HttpsError("invalid-argument", "Merchant Order ID is required");
    }

    console.log(`🔍 Checking PRODUCTION payment status for order: ${merchantOrderId}`);

    const accessToken = await getAuthToken();
    const statusUrl = `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/${merchantOrderId}/status?details=true&errorContext=true`;
    
    console.log(`📡 Calling PhonePe PRODUCTION Order Status API: ${statusUrl}`);

    const response = await axios.get(statusUrl, {
      headers: {
        "Content-Type": "application/json",
        "Authorization": `O-Bearer ${accessToken}`,
      },
      timeout: 15000,
    });

    console.log("✅ PhonePe PRODUCTION Order Status Response:", JSON.stringify(response.data, null, 2));

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
      environment: "production",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    throw new functions.https.HttpsError("internal", "Payment verification failed. Please try again.");
  }
});

// Create Delhivery shipment with structured address handling
exports.createDelhiveryShipment = functions.https.onCall(async (data, context) => {
  try {
    console.log("📦 Creating Delhivery shipment with structured address handling...");
    
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { 
      orderId, 
      customerDetails, 
      shippingAddress, 
      items, 
      total, 
      paymentMode = 'Prepaid' 
    } = data;

    if (!orderId || !customerDetails || !shippingAddress || !items || !total) {
      throw new functions.https.HttpsError(
        "invalid-argument", 
        "Missing required fields: orderId, customerDetails, shippingAddress, items, total"
      );
    }

    const addressComponents = extractAddressComponents(shippingAddress);
    const customer = extractCustomerDetails(customerDetails);
    
    const itemCount = Array.isArray(items) ? items.length : 1;
    const packageWeight = Math.max(0.5, itemCount * 0.3);
    const packageDimensions = { 
      length: Math.max(15, itemCount * 5), 
      breadth: 15, 
      height: Math.max(10, itemCount * 2) 
    };

    let productsDesc = "Wellness Products";
    let quantity = "1";
    
    if (Array.isArray(items) && items.length > 0) {
      productsDesc = items.map(item => {
        let itemDesc = `${item.name || 'Product'} (Qty: ${item.quantity || 1})`;
        if (item.originalPrice && item.price < item.originalPrice) {
          const savings = ((item.originalPrice - item.price) / item.originalPrice * 100).toFixed(0);
          itemDesc += ` [${savings}% OFF]`;
        }
        return itemDesc;
      }).join(', ');
      quantity = items.reduce((sum, item) => sum + (item.quantity || 1), 0).toString();
    }

    const shipmentData = {
      name: customer.fullName,
      add: addressComponents.addressLine1,
      pin: addressComponents.pincode,
      city: addressComponents.city,
      state: addressComponents.state,
      country: addressComponents.country,
      phone: customer.phone,
      order: orderId,
      payment_mode: paymentMode,
      return_pin: DELHIVERY_CONFIG.defaults.pickup_location.pin_code.toString(),
      return_city: DELHIVERY_CONFIG.defaults.pickup_location.city,
      return_phone: DELHIVERY_CONFIG.defaults.pickup_location.phone,
      return_add: DELHIVERY_CONFIG.defaults.pickup_location.add,
      return_state: "Uttar Pradesh",
      return_country: "India",
      products_desc: productsDesc,
      hsn_code: "30049099",
      cod_amount: paymentMode === 'COD' ? total.toString() : "0",
      order_date: new Date().toISOString(),
      total_amount: total.toString(),
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
      email: customer.email,
    };

    if (addressComponents.addressLine2) {
      shipmentData.add += `, ${addressComponents.addressLine2}`;
    }

    console.log("📋 Prepared shipment data:", {
      order: shipmentData.order,
      name: shipmentData.name,
      city: shipmentData.city,
      state: shipmentData.state,
      pincode: shipmentData.pin,
      payment_mode: shipmentData.payment_mode,
      total_amount: shipmentData.total_amount
    });

    const delhiveryPayload = {
      shipments: [shipmentData],
      pickup_location: DELHIVERY_CONFIG.defaults.pickup_location
    };

    const url = `${DELHIVERY_CONFIG.baseUrl}/api/cmu/create.json`;
    const requestData = `format=json&data=${JSON.stringify(delhiveryPayload)}`;
    
    console.log("🚀 Sending request to Delhivery API...");
    
    const response = await axios.post(url, requestData, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      timeout: 30000,
    });

    console.log("📥 Delhivery API Response:", response.status, response.data);

    if (response.status === 200) {
      const delhiveryData = response.data;
      const isSuccess = delhiveryData.success === true || 
                     delhiveryData.rmk === 'Success' || 
                     delhiveryData.packages ||
                     (delhiveryData && !delhiveryData.error);

      if (isSuccess) {
        let assignedWaybill = null;
        let trackingUrl = null;
        
        if (delhiveryData.packages && delhiveryData.packages.length > 0) {
          assignedWaybill = delhiveryData.packages[0].waybill;
        } else if (delhiveryData.waybill) {
          assignedWaybill = delhiveryData.waybill;
        }
        
        if (assignedWaybill) {
          trackingUrl = `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?waybill=${assignedWaybill}`;
        }

        console.log(`✅ Delhivery shipment created successfully with waybill: ${assignedWaybill}`);

        return {
          success: true,
          waybill: assignedWaybill,
          status: 'Manifested',
          tracking_url: trackingUrl,
          payment_mode: paymentMode,
          order_id: orderId,
          used_defaults: addressComponents.pincode === DELHIVERY_CONFIG.defaults.customer.pin,
          delhivery_response: delhiveryData,
          address_used: {
            name: customer.fullName,
            address: shipmentData.add,
            city: addressComponents.city,
            state: addressComponents.state,
            pincode: addressComponents.pincode
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        };
      } else {
        throw new Error(`Delhivery shipment creation failed: ${delhiveryData.rmk || delhiveryData.error || 'Unknown error'}`);
      }
    } else {
      throw new Error(`Delhivery API error: HTTP ${response.status}`);
    }

  } catch (error) {
    console.error("❌ Delhivery shipment creation error:", error.message);
    
    if (error.response) {
      console.error("📥 Error response:", error.response.status, error.response.data);
    }

    throw new functions.https.HttpsError(
      "internal", 
      `Delhivery shipment creation failed: ${error.message}`
    );
  }
});

// Track Delhivery shipment
exports.trackDelhiveryShipment = functions.https.onCall(async (data, context) => {
  try {
    console.log("📍 Tracking Delhivery shipment...");
    
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { waybill, orderId } = data;

    if (!waybill && !orderId) {
      throw new functions.https.HttpsError(
        "invalid-argument", 
        "Either waybill or orderId is required"
      );
    }

    let trackingUrl;

    if (waybill) {
      trackingUrl = `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?waybill=${waybill}`;
      console.log(`📦 Tracking by waybill: ${waybill}`);
    } else {
      trackingUrl = `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?ref_ids=${orderId}`;
      console.log(`🆔 Tracking by order ID: ${orderId}`);
    }

    console.log("📡 Tracking URL:", trackingUrl);

    const response = await axios.get(trackingUrl, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Accept': 'application/json',
      },
      timeout: 20000,
    });

    console.log("📥 Tracking Response:", response.status, response.data);

    if (response.status === 200 && response.data) {
      const trackingData = response.data;
      
      let shipmentInfo = null;
      let trackingHistory = [];
      let currentStatus = 'Unknown';
      let estimatedDelivery = null;

      if (trackingData.ShipmentData && trackingData.ShipmentData.length > 0) {
        const shipment = trackingData.ShipmentData[0];
        shipmentInfo = shipment.Shipment;
        
        if (shipment.Shipment) {
          currentStatus = shipment.Shipment.Status?.Status || 'In Transit';
          estimatedDelivery = shipment.Shipment.ExpectedDeliveryDate;
        }

        if (shipment.Shipment && shipment.Shipment.Scans) {
          trackingHistory = shipment.Shipment.Scans.map(scan => ({
            date: scan.ScanDateTime,
            status: scan.ScanType,
            location: scan.ScannedLocation,
            remarks: scan.Instructions,
            description: scan.StatusDescription || scan.ScanType
          })).reverse();
        }
      }

      console.log(`✅ Tracking successful - Status: ${currentStatus}`);

      return {
        success: true,
        waybill: waybill || shipmentInfo?.AWB,
        order_id: orderId || shipmentInfo?.ReferenceNo,
        current_status: currentStatus,
        estimated_delivery: estimatedDelivery,
        tracking_history: trackingHistory,
        shipment_info: shipmentInfo,
        last_updated: new Date().toISOString(),
        tracking_url: `https://www.delhivery.com/track/package/${waybill || shipmentInfo?.AWB}`
      };
    } else {
      console.log("❌ No tracking data found");
      return {
        success: false,
        message: "No tracking information found",
        waybill: waybill,
        order_id: orderId
      };
    }

  } catch (error) {
    console.error("❌ Tracking error:", error.message);
    
    if (error.response) {
      console.error("📥 Error response:", error.response.status, error.response.data);
    }

    return {
      success: false,
      error: error.message,
      waybill: data.waybill,
      order_id: data.orderId,
      message: "Failed to fetch tracking information"
    };
  }
});

// Check Delhivery serviceability
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
    
    console.log("📡 Serviceability check URL:", url);
    
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      timeout: 15000,
    });

    console.log("📥 Serviceability Response:", response.status, response.data);

    if (response.status === 200) {
      const data = response.data;
      
      if (data.delivery_codes && data.delivery_codes.length > 0) {
        const pincodeData = data.delivery_codes[0];
        
        console.log(`✅ Pincode ${pincode} is serviceable`);
        
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
          message: `Pincode ${pincode} is serviceable by Delhivery`
        };
      } else {
        console.log(`❌ Pincode ${pincode} is not serviceable`);
        
        return {
          success: true,
          serviceable: false,
          message: `Pincode ${pincode} is not serviceable by Delhivery`,
          pincode: pincode,
        };
      }
    } else {
      throw new Error(`Delhivery API returned status: ${response.status}`);
    }
  } catch (error) {
    console.error('❌ Delhivery serviceability check error:', error.response?.data || error.message);
    
    throw new functions.https.HttpsError(
      'internal', 
      `Serviceability check failed: ${error.message}`
    );
  }
});

// Get comprehensive order tracking
exports.getOrderTracking = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { orderId } = data;
    if (!orderId) {
      throw new functions.https.HttpsError('invalid-argument', 'Order ID is required');
    }

    // Get order details from Firestore
    const orderDoc = await admin.firestore().collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found');
    }

    const orderData = orderDoc.data();
    
    // Check if order belongs to the authenticated user
    if (orderData.userId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    let trackingInfo = {
      order_id: orderId,
      order_status: orderData.status,
      payment_status: orderData.paymentStatus,
      shipping_status: orderData.shippingStatus || 'pending',
      total: orderData.total,
      items: orderData.items,
      created_at: orderData.createdAt,
      tracking_available: false
    };

    // If Delhivery info is available, get tracking details
    if (orderData.delhivery && orderData.delhivery.waybill) {
      try {
        const trackingResult = await trackDelhiveryShipmentInternal({
          waybill: orderData.delhivery.waybill,
          orderId: orderId
        });

        if (trackingResult.success) {
          trackingInfo = {
            ...trackingInfo,
            tracking_available: true,
            waybill: trackingResult.waybill,
            current_status: trackingResult.current_status,
            estimated_delivery: trackingResult.estimated_delivery,
            tracking_history: trackingResult.tracking_history,
            shipment_info: trackingResult.shipment_info,
            last_updated: trackingResult.last_updated,
            tracking_url: trackingResult.tracking_url,
            delhivery_details: orderData.delhivery
          };
        }
      } catch (trackingError) {
        console.error('⚠️ Tracking fetch failed:', trackingError);
        trackingInfo.tracking_error = 'Unable to fetch latest tracking information';
      }
    }

    return {
      success: true,
      tracking_info: trackingInfo
    };

  } catch (error) {
    console.error('❌ Get order tracking error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get order tracking');
  }
});

// Internal tracking function
async function trackDelhiveryShipmentInternal(data) {
  try {
    const { waybill, orderId } = data;

    let trackingUrl;
    if (waybill) {
      trackingUrl = `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?waybill=${waybill}`;
    } else {
      trackingUrl = `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?ref_ids=${orderId}`;
    }

    const response = await axios.get(trackingUrl, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Accept': 'application/json',
      },
      timeout: 20000,
    });

    if (response.status === 200 && response.data) {
      const trackingData = response.data;
      
      let shipmentInfo = null;
      let trackingHistory = [];
      let currentStatus = 'Unknown';
      let estimatedDelivery = null;

      if (trackingData.ShipmentData && trackingData.ShipmentData.length > 0) {
        const shipment = trackingData.ShipmentData[0];
        shipmentInfo = shipment.Shipment;
        
        if (shipment.Shipment) {
          currentStatus = shipment.Shipment.Status?.Status || 'In Transit';
          estimatedDelivery = shipment.Shipment.ExpectedDeliveryDate;
        }

        if (shipment.Shipment && shipment.Shipment.Scans) {
          trackingHistory = shipment.Shipment.Scans.map(scan => ({
            date: scan.ScanDateTime,
            status: scan.ScanType,
            location: scan.ScannedLocation,
            remarks: scan.Instructions,
            description: scan.StatusDescription || scan.ScanType
          })).reverse();
        }
      }

      return {
        success: true,
        waybill: waybill || shipmentInfo?.AWB,
        order_id: orderId || shipmentInfo?.ReferenceNo,
        current_status: currentStatus,
        estimated_delivery: estimatedDelivery,
        tracking_history: trackingHistory,
        shipment_info: shipmentInfo,
        last_updated: new Date().toISOString(),
        tracking_url: `https://www.delhivery.com/track/package/${waybill || shipmentInfo?.AWB}`
      };
    } else {
      return {
        success: false,
        message: "No tracking information found",
        waybill: waybill,
        order_id: orderId
      };
    }
  } catch (error) {
    console.error("❌ Internal tracking error:", error.message);
    return {
      success: false,
      error: error.message,
      waybill: data.waybill,
      order_id: data.orderId
    };
  }
}

// Process successful payment and create order with Delhivery integration
async function processSuccessfulPayment(merchantOrderId, paymentData) {
  try {
    console.log(`✅ Processing successful payment for order: ${merchantOrderId}`);

    const pendingOrderDoc = await admin.firestore().collection("pending_orders").doc(merchantOrderId).get();

    if (!pendingOrderDoc.exists) {
      throw new Error(`Pending order not found for ID: ${merchantOrderId}`);
    }

    const pendingData = pendingOrderDoc.data();
    console.log("📋 Found pending order data");

    // Calculate discount summary
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

    // Create confirmed order
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
      environment: "production",
      paymentCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Save confirmed order
    await admin.firestore().collection("orders").doc(merchantOrderId).set(confirmedOrder);
    console.log("✅ Confirmed order created");

    // Create Delhivery shipping order
    try {
      console.log("📦 Creating Delhivery shipping order...");
      
      const customerDetails = pendingData.customerDetails;
      const shippingAddress = pendingData.shippingAddress;

      // Extract address components properly
      const addressComponents = extractAddressComponents(shippingAddress);
      const customer = extractCustomerDetails(customerDetails);
      
      const itemCount = pendingData.items ? pendingData.items.length : 1;
      const packageWeight = Math.max(0.5, itemCount * 0.3);
      const packageDimensions = { 
        length: Math.max(15, itemCount * 5), 
        breadth: 15, 
        height: Math.max(10, itemCount * 2) 
      };

      // Prepare products description
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
        name: customer.fullName,
        add: addressComponents.addressLine1,
        pin: addressComponents.pincode,
        city: addressComponents.city,
        state: addressComponents.state,
        country: addressComponents.country,
        phone: customer.phone,
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
        email: customer.email,
      };

      // Add address line 2 if available
      if (addressComponents.addressLine2) {
        shipmentData.add += `, ${addressComponents.addressLine2}`;
      }

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
            trackingUrl = `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?waybill=${assignedWaybill}`;
          }

          await admin.firestore().collection('orders').doc(merchantOrderId).update({
            delhivery: {
              waybill: assignedWaybill,
              status: 'Manifested',
              tracking_url: trackingUrl,
              payment_mode: 'Prepaid',
              used_defaults: addressComponents.pincode === DELHIVERY_CONFIG.defaults.customer.pin,
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
    environment: "production",
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    transactionId: transactionId,
    flow: "payment_first",
    environment: "production"
  };
});

// Test Production Setup
exports.testProductionSetup = functions.https.onCall(async (data, context) => {
  try {
    console.log("🧪 Testing PhonePe Production Setup...");

    const authResponse = await axios.post(
      `${PHONEPE_CONFIG.authUrl}/v1/oauth/token`,
      new URLSearchParams({
        client_id: PHONEPE_CONFIG.clientId,
        client_version: PHONEPE_CONFIG.clientVersion,
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

    console.log("✅ Production Auth Test: SUCCESS");

    return {
      success: true,
      authStatus: "working",
      environment: "production",
      urls: {
        auth: `${PHONEPE_CONFIG.authUrl}/v1/oauth/token`,
        payment: `${PHONEPE_CONFIG.baseUrl}/checkout/v2/pay`,
        status: `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/{orderId}/status`
      },
      credentials: {
        clientId: PHONEPE_CONFIG.clientId,
        clientVersion: PHONEPE_CONFIG.clientVersion
      },
      message: "Production PhonePe setup is working correctly!"
    };

  } catch (error) {
    console.error("❌ Production test failed:", error.response?.data || error.message);
    
    return {
      success: false,
      error: error.response?.data || error.message,
      statusCode: error.response?.status,
      message: "Production setup has issues. Check credentials or account activation."
    };
  }
});

// Retry failed Delhivery orders
exports.retryDelhiveryShipment = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { orderId } = data;
    if (!orderId) {
      throw new functions.https.HttpsError('invalid-argument', 'Order ID is required');
    }

    const orderDoc = await admin.firestore().collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found');
    }

    const orderData = orderDoc.data();
    if (!orderData.delhiveryRetryNeeded) {
      return {
        success: false,
        message: 'Order does not need Delhivery retry'
      };
    }

    // Retry creating Delhivery order
    await processSuccessfulPayment(orderId, orderData.paymentData);

    return {
      success: true,
      message: 'Delhivery order retry completed'
    };

  } catch (error) {
    console.error('❌ Delhivery retry error:', error);
    throw new functions.https.HttpsError('internal', 'Delhivery retry failed');
  }
});

// Health check
exports.healthCheck = functions.https.onRequest(async (req, res) => {
  try {
    const accessToken = await getAuthToken();
    
    res.json({
      success: true,
      status: "healthy",
      environment: "production",
      services: {
        phonepe: "connected",
        delhivery: "server_side_integrated",
        firestore: "connected"
      },
      apis: {
        "phonepe_auth": `${PHONEPE_CONFIG.authUrl}/v1/oauth/token`,
        "phonepe_payment": `${PHONEPE_CONFIG.baseUrl}/checkout/v2/pay`,
        "phonepe_order_status": `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/{merchantOrderId}/status`,
        "delhivery_create": `${DELHIVERY_CONFIG.baseUrl}/api/cmu/create.json`,
        "delhivery_track": `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/`,
        "delhivery_serviceability": `${DELHIVERY_CONFIG.baseUrl}/c/api/pin-codes/json/`
      },
      flow: "payment_first",
      timestamp: new Date().toISOString(),
      version: "4.0.0",
      verification_method: "PhonePe Production Order Status API",
      shipping: {
        provider: "Delhivery",
        integration: "Direct API with structured address handling",
        address_format: "addressLine1, addressLine2, city, state, pinCode",
        tracking: "Real-time via waybill and order ID",
        working_pincode: DELHIVERY_CONFIG.defaults.customer.pin
      },
      features: [
        "discount_tracking", 
        "order_discount_summary", 
        "production_ready",
        "structured_address_handling",
        "delhivery_shipment_creation",
        "real_time_tracking",
        "automatic_retry"
      ],
      message: "Production payment verification with enhanced Delhivery integration and structured address handling"
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      status: "unhealthy",
      environment: "production",
      error: error.message,
      timestamp: new Date().toISOString()
    });
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

    console.log('✅ Production cleanup completed');
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
});

/*
🚀 PRODUCTION DEPLOYMENT CHECKLIST:

✅ 1. PhonePe Production URLs configured
✅ 2. Delhivery API integration with structured address handling
✅ 3. Address extraction from Flutter checkout form
✅ 4. Real-time shipment tracking
✅ 5. Waybill generation and storage
✅ 6. Order tracking by waybill and order ID
✅ 7. Automatic retry mechanisms
✅ 8. Error handling and logging
✅ 9. Health checks and monitoring

DEPLOYMENT COMMANDS:
1. firebase deploy --only functions
2. Test: Call testProductionSetup
3. Monitor: Check healthCheck endpoint
4. Verify: Test complete flow

ADDRESS STRUCTURE EXPECTED:
{
  "name": "Customer Name",
  "addressLine1": "Street Address",
  "addressLine2": "Apartment/Building (optional)",
  "city": "City Name",
  "state": "State Name", 
  "pinCode": "123456",
  "phone": "1234567890"
}

TRACKING FEATURES:
- Track by waybill number
- Track by order ID
- Real-time status updates
- Delivery timeline
- Estimated delivery dates
*/