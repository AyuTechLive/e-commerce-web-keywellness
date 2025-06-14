// functions/index.js - Optimized PhonePe + Delhivery Integration
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// PhonePe Production Configuration
const PHONEPE_CONFIG = {
  clientId: "SU2505231813159051637752",
  clientSecret: "5bbc7348-5e26-44b4-8511-449141d6f097",
  baseUrl: "https://api.phonepe.com/apis/pg",
  authUrl: "https://api.phonepe.com/apis/identity-manager",
  clientVersion: "1",
  environment: "production"
};

// Delhivery Configuration
const DELHIVERY_CONFIG = {
  token: '68743057c62717b9f0c08fa3f3d25f25cde9cb8a',
  clientName: 'KEIWAYWELLNESSSURFACE-B2C',
  baseUrl: 'https://track.delhivery.com',
  trackingUrl: 'https://track.delhivery.com',
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
      seller_name: "Keiway Wellness Private Limited",
      seller_add: "Shop no 201, Green City ,Hanumangarh town",
      seller_gst_tin: "08AALCK6059R1ZJ",
      seller_inv: "KW",
    }
  }
};

// Cache for auth tokens
let authTokenCache = null;
let tokenExpiry = 0;

// Optimized auth token function with caching
async function getAuthToken() {
  try {
    const now = Date.now();
    if (authTokenCache && now < tokenExpiry) {
      return authTokenCache;
    }

    const response = await axios.post(
      `${PHONEPE_CONFIG.authUrl}/v1/oauth/token`,
      new URLSearchParams({
        client_id: PHONEPE_CONFIG.clientId,
        client_version: PHONEPE_CONFIG.clientVersion,
        client_secret: PHONEPE_CONFIG.clientSecret,
        grant_type: "client_credentials",
      }),
      {
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        timeout: 8000,
      }
    );

    authTokenCache = response.data.access_token;
    tokenExpiry = now + (50 * 60 * 1000); // 50 minutes cache
    
    return authTokenCache;
  } catch (error) {
    throw new Error(`Auth failed: ${error.response?.data?.message || error.message}`);
  }
}

// Optimized transaction ID generation
function generateTransactionId() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, "0");
  return `TXN${timestamp}${random}`.substring(0, 34);
}

// Optimized address extraction
function extractAddressComponents(addressData) {
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
      const pincodeMatch = parts[parts.length - 1].match(/\d{6}/);
      if (pincodeMatch) pincode = pincodeMatch[0];
    }
  }
  
  return {
    name: name || DELHIVERY_CONFIG.defaults.customer.name,
    addressLine1: addressLine1 || DELHIVERY_CONFIG.defaults.customer.add,
    addressLine2: addressLine2 || '',
    city: city || DELHIVERY_CONFIG.defaults.customer.city,
    state: state || DELHIVERY_CONFIG.defaults.customer.state,
    pincode: pincode || DELHIVERY_CONFIG.defaults.customer.pin,
    phone: phone || DELHIVERY_CONFIG.defaults.customer.phone,
    country: 'India'
  };
}

// Optimized customer details extraction
function extractCustomerDetails(customerData) {
  const safeCustomer = {
    name: customerData?.name || DELHIVERY_CONFIG.defaults.customer.name,
    lastName: customerData?.lastName || '',
    email: customerData?.email || 'customer@example.com',
    phone: customerData?.phone || DELHIVERY_CONFIG.defaults.customer.phone
  };
  
  safeCustomer.fullName = `${safeCustomer.name} ${safeCustomer.lastName}`.trim();
  return safeCustomer;
}

// Optimized PhonePe Payment Initiation
exports.initiatePhonePePayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const { amount, orderId, userId, userPhone, redirectUrl } = data;

  if (!amount || !orderId || !userId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  const amountInPaisa = Math.round(amount * 100);
  if (amountInPaisa < 100) {
    throw new functions.https.HttpsError("invalid-argument", "Amount too low");
  }

  try {
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

    const response = await axios.post(
      `${PHONEPE_CONFIG.baseUrl}/checkout/v2/pay`,
      paymentData,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `O-Bearer ${accessToken}`,
        },
        timeout: 10000,
      }
    );

    // Save payment request without excessive logging
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

    return {
      success: true,
      data: response.data,
      flow: "payment_first",
      environment: "production",
      message: "Payment initiated"
    };
  } catch (error) {
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

// Optimized Payment Verification
exports.verifyPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const { merchantOrderId } = data;
  if (!merchantOrderId) {
    throw new functions.https.HttpsError("invalid-argument", "Order ID required");
  }

  try {
    const accessToken = await getAuthToken();
    const statusUrl = `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/${merchantOrderId}/status?details=true&errorContext=true`;
    
    const response = await axios.get(statusUrl, {
      headers: {
        "Content-Type": "application/json",
        "Authorization": `O-Bearer ${accessToken}`,
      },
      timeout: 10000,
    });

    const paymentRef = admin.firestore().collection("payment_requests").doc(merchantOrderId);
    await paymentRef.update({
      verificationResponse: response.data,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const orderData = response.data;
    const orderState = orderData.state;
    
    switch (orderState) {
      case "COMPLETED":
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
            message: "Payment successful! Order confirmed."
          };
        } catch (orderProcessingError) {
          return {
            success: true,
            status: "completed",
            data: orderData,
            message: "Payment successful! Order confirmation in progress.",
            warning: "Order processing delayed"
          };
        }
        
      case "PENDING":
        await paymentRef.update({ status: "payment_pending" });
        return {
          success: false,
          status: "pending",
          data: orderData,
          message: "Payment processing...",
          retry: true
        };
        
      case "FAILED":
        await paymentRef.update({
          status: "payment_failed",
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          failureReason: orderData.errorCode || "Payment failed"
        });

        return {
          success: false,
          status: "failed",
          data: orderData,
          message: orderData.errorContext?.description || "Payment failed",
          error: orderData.errorCode || "PAYMENT_FAILED"
        };
        
      default:
        return {
          success: false,
          status: orderState?.toLowerCase() || "unknown",
          data: orderData,
          message: `Payment status: ${orderState}`,
          retry: true
        };
    }

  } catch (error) {
    if (error.response?.status === 404) {
      return {
        success: false,
        status: "not_found",
        message: "Payment verification in progress...",
        retry: true
      };
    }

    if (error.response?.status === 401) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication failed");
    }

    await admin.firestore().collection("verification_errors").add({
      orderId: data.merchantOrderId,
      error: error.response?.data || error.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    throw new functions.https.HttpsError("internal", "Payment verification failed");
  }
});

// Optimized Delhivery Shipment Creation
exports.createDelhiveryShipment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const { orderId, customerDetails, shippingAddress, items, total, paymentMode = 'Prepaid' } = data;

  if (!orderId || !customerDetails || !shippingAddress || !items || !total) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  try {
    const addressComponents = extractAddressComponents(shippingAddress);
    const customer = extractCustomerDetails(customerDetails);
    
    const itemCount = Array.isArray(items) ? items.length : 1;
    const packageWeight = Math.max(0.5, itemCount * 0.3);
    
    let productsDesc = "Wellness Products";
    let quantity = "1";
    
    if (Array.isArray(items) && items.length > 0) {
      productsDesc = items.map(item => 
        `${item.name || 'Product'} (Qty: ${item.quantity || 1})`
      ).join(', ');
      quantity = items.reduce((sum, item) => sum + (item.quantity || 1), 0).toString();
    }

    const shipmentData = {
      name: customer.fullName,
      add: addressComponents.addressLine1 + (addressComponents.addressLine2 ? `, ${addressComponents.addressLine2}` : ''),
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
      shipment_width: "15",
      shipment_height: Math.max(10, itemCount * 2).toString(),
      weight: packageWeight.toString(),
      seller_gst_tin: DELHIVERY_CONFIG.defaults.business.seller_gst_tin,
      shipping_mode: "Surface",
      address_type: "home",
      email: customer.email,
    };

    const delhiveryPayload = {
      shipments: [shipmentData],
      pickup_location: DELHIVERY_CONFIG.defaults.pickup_location
    };

    const url = `${DELHIVERY_CONFIG.baseUrl}/api/cmu/create.json`;
    const requestData = `format=json&data=${JSON.stringify(delhiveryPayload)}`;
    
    const response = await axios.post(url, requestData, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      timeout: 20000,
    });

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

        return {
          success: true,
          waybill: assignedWaybill,
          status: 'Manifested',
          tracking_url: trackingUrl,
          payment_mode: paymentMode,
          order_id: orderId,
          delhivery_response: delhiveryData,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        };
      } else {
        throw new Error(`Shipment creation failed: ${delhiveryData.rmk || delhiveryData.error || 'Unknown error'}`);
      }
    } else {
      throw new Error(`Delhivery API error: HTTP ${response.status}`);
    }

  } catch (error) {
    throw new functions.https.HttpsError("internal", `Shipment creation failed: ${error.message}`);
  }
});

// Optimized Shipment Tracking
exports.trackDelhiveryShipment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const { waybill, orderId } = data;
  if (!waybill && !orderId) {
    throw new functions.https.HttpsError("invalid-argument", "Waybill or orderId required");
  }

  try {
    const trackingUrl = waybill 
      ? `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?waybill=${waybill}`
      : `${DELHIVERY_CONFIG.trackingUrl}/api/v1/packages/json/?ref_ids=${orderId}`;

    const response = await axios.get(trackingUrl, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
        'Accept': 'application/json',
      },
      timeout: 15000,
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
    return {
      success: false,
      error: error.message,
      waybill: data.waybill,
      order_id: data.orderId,
      message: "Failed to fetch tracking information"
    };
  }
});

// Optimized Serviceability Check
exports.checkDelhiveryServiceability = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { pincode } = data;
  if (!pincode || pincode.length !== 6) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid 6-digit pincode required');
  }

  try {
    const url = `${DELHIVERY_CONFIG.baseUrl}/c/api/pin-codes/json/?filter_codes=${pincode}`;
    
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Token ${DELHIVERY_CONFIG.token}`,
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
          message: `Pincode ${pincode} is serviceable`
        };
      } else {
        return {
          success: true,
          serviceable: false,
          message: `Pincode ${pincode} is not serviceable`,
          pincode: pincode,
        };
      }
    } else {
      throw new Error(`API returned status: ${response.status}`);
    }
  } catch (error) {
    throw new functions.https.HttpsError('internal', `Serviceability check failed: ${error.message}`);
  }
});

// Optimized Order Processing
async function processSuccessfulPayment(merchantOrderId, paymentData) {
  const pendingOrderDoc = await admin.firestore().collection("pending_orders").doc(merchantOrderId).get();

  if (!pendingOrderDoc.exists) {
    throw new Error(`Pending order not found: ${merchantOrderId}`);
  }

  const pendingData = pendingOrderDoc.data();

  // Calculate discounts quickly
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

  await admin.firestore().collection("orders").doc(merchantOrderId).set(confirmedOrder);

  // Create Delhivery shipment
  try {
    const customerDetails = pendingData.customerDetails;
    const shippingAddress = pendingData.shippingAddress;
    const addressComponents = extractAddressComponents(shippingAddress);
    const customer = extractCustomerDetails(customerDetails);
    
    const itemCount = pendingData.items ? pendingData.items.length : 1;
    const packageWeight = Math.max(0.5, itemCount * 0.3);

    let productsDesc = "Wellness Products";
    let quantity = "1";
    
    if (pendingData.items && Array.isArray(pendingData.items)) {
      productsDesc = pendingData.items.map(item => 
        `${item.name || 'Product'} (Qty: ${item.quantity || 1})`
      ).join(', ');
      quantity = pendingData.items.reduce((sum, item) => sum + (item.quantity || 1), 0).toString();
    }

    const shipmentData = {
      name: customer.fullName,
      add: addressComponents.addressLine1 + (addressComponents.addressLine2 ? `, ${addressComponents.addressLine2}` : ''),
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
      shipment_width: "15",
      shipment_height: Math.max(10, itemCount * 2).toString(),
      weight: packageWeight.toString(),
      seller_gst_tin: DELHIVERY_CONFIG.defaults.business.seller_gst_tin,
      shipping_mode: "Surface",
      address_type: "home",
      email: customer.email,
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
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            response: delhiveryData
          },
          shippingStatus: 'manifested',
          shippingPartner: 'delhivery',
          status: 'processing',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        throw new Error(`Delhivery order creation failed: ${delhiveryData.rmk || 'Unknown error'}`);
      }
    }

  } catch (delhiveryError) {
    await admin.firestore().collection('orders').doc(merchantOrderId).update({
      delhiveryError: delhiveryError.message,
      delhiveryRetryNeeded: true,
      shippingPartner: 'delhivery',
      note: 'Payment successful, order confirmed, shipping setup failed - will retry',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await admin.firestore().collection("pending_orders").doc(merchantOrderId).delete();
}

// Generate Transaction ID
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

// Optimized Test Setup
exports.testProductionSetup = functions.https.onCall(async (data, context) => {
  try {
    const authResponse = await axios.post(
      `${PHONEPE_CONFIG.authUrl}/v1/oauth/token`,
      new URLSearchParams({
        client_id: PHONEPE_CONFIG.clientId,
        client_version: PHONEPE_CONFIG.clientVersion,
        client_secret: PHONEPE_CONFIG.clientSecret,
        grant_type: "client_credentials",
      }),
      {
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        timeout: 8000,
      }
    );

    return {
      success: true,
      authStatus: "working",
      environment: "production",
      message: "Production setup working correctly!"
    };

  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message,
      statusCode: error.response?.status,
      message: "Production setup has issues."
    };
  }
});

// Health Check
exports.healthCheck = functions.https.onRequest(async (req, res) => {
  try {
    await getAuthToken();
    
    res.json({
      success: true,
      status: "healthy",
      environment: "production",
      services: {
        phonepe: "connected",
        delhivery: "integrated",
        firestore: "connected"
      },
      flow: "payment_first",
      timestamp: new Date().toISOString(),
      version: "4.1.0-optimized"
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

// Cleanup old logs
exports.cleanupTransactionLogs = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 30);

  try {
    // Clean transaction logs
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
    }

    // Clean pending orders
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
    }

  } catch (error) {
    console.error('Cleanup error:', error);
  }
});