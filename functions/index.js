// functions/index.js - Updated PhonePe Integration with V2 API
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
  baseUrl: "https://api-preprod.phonepe.com/apis/pg-sandbox", // UAT
  // baseUrl: "https://api.phonepe.com/apis/pg", // Production
  clientId: "TEST-M23675ZMAG3KW_25052", // Replace with actual client ID
  clientSecret: "MGJjNDJlYjMtODMzZS00OGJiLTkwY2QtNzY1YzFiZDNmNTli", // Replace with actual client secret
};

/**
 * Get OAuth Token for PhonePe V2 API
 */
async function getAuthToken() {
  try {
    const response = await axios.post(
      `${PHONEPE_CONFIG.baseUrl}/v1/oauth/token`,
      new URLSearchParams({
        client_id: PHONEPE_CONFIG.clientId,
        client_version: "1", // Use "1" for UAT
        client_secret: PHONEPE_CONFIG.clientSecret,
        grant_type: "client_credentials",
      }),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    return response.data.access_token;
  } catch (error) {
    console.error("❌ Auth token error:", error.response?.data || error.message);
    throw new Error("Failed to get auth token");
  }
}

/**
 * Generate unique transaction ID
 */
function generateTransactionId() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, "0");
  return `TXN${timestamp}${random}`.substring(0, 34);
}

// Create Payment using V2 API
exports.initiatePhonePePayment = functions.https.onCall(async (data, context) => {
  try {
    console.log("🚀 Initiating PhonePe Payment with V2 API...");

    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { amount, orderId, userId, userPhone, redirectUrl } = data;

    // Validate required fields
    if (!amount || !orderId || !userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: amount, orderId, userId"
      );
    }

    // Validate amount (minimum 100 paisa = ₹1)
    const amountInPaisa = Math.round(amount * 100);
    if (amountInPaisa < 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Amount too low. Minimum amount is ₹1"
      );
    }

    // Get auth token
    const accessToken = await getAuthToken();

    // Create V2 payment payload
    const paymentData = {
      merchantOrderId: orderId,
      amount: amountInPaisa,
      expireAfter: 1200, // 20 minutes
      metaInfo: {
        udf1: userId,
        udf2: userPhone || "9999999999",
        udf3: "Flutter Web Payment",
        udf4: "",
        udf5: "",
      },
      paymentFlow: {
        type: "PG_CHECKOUT",
        message: "Payment for order",
        merchantUrls: {
          redirectUrl: redirectUrl || `https://${context.rawRequest.headers.host}/payment-success`,
        },
      },
    };

    console.log("📋 V2 Payment Payload:", JSON.stringify(paymentData, null, 2));

    // Make request to V2 API
    const response = await axios.post(
      `${PHONEPE_CONFIG.baseUrl}/checkout/v2/pay`,
      paymentData,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `O-Bearer ${accessToken}`,
        },
      }
    );

    console.log("✅ PhonePe V2 Response:", response.data);

    // Save payment initiation to Firestore
    await admin.firestore().collection("payment_requests").doc(orderId).set({
      userId: context.auth.uid,
      orderId: orderId,
      amount: amount,
      amountInPaisa: amountInPaisa,
      status: "initiated",
      phonepeResponse: response.data,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      data: response.data,
    };
  } catch (error) {
    console.error("❌ PhonePe V2 API Error:", error.response?.data || error.message);

    // Log error to Firestore
    if (data.orderId) {
      await admin.firestore().collection("payment_errors").add({
        orderId: data.orderId,
        error: error.response?.data || error.message,
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

// Verify Payment Status using V2 API
exports.verifyPayment = functions.https.onCall(async (data, context) => {
  try {
    console.log("🔍 Verifying payment with V2 API...");

    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const { merchantOrderId } = data;

    if (!merchantOrderId) {
      throw new functions.https.HttpsError("invalid-argument", "Merchant Order ID is required");
    }

    // Get auth token
    const accessToken = await getAuthToken();

    // Call V2 status API
    const response = await axios.get(
      `${PHONEPE_CONFIG.baseUrl}/checkout/v2/order/${merchantOrderId}/status`,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `O-Bearer ${accessToken}`,
        },
      }
    );

    console.log("✅ V2 Verification Response:", response.data);

    // Update payment status in Firestore
    const paymentRef = admin.firestore().collection("payment_requests").doc(merchantOrderId);
    await paymentRef.update({
      verificationResponse: response.data,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: response.data.state === "COMPLETED" ? "completed" : 
              response.data.state === "FAILED" ? "failed" : "pending",
    });

    return {
      success: true,
      data: response.data,
    };
  } catch (error) {
    console.error("❌ V2 Verification Error:", error.response?.data || error.message);
    throw new functions.https.HttpsError("internal", "Payment verification failed");
  }
});

// Generate unique transaction ID function
exports.generateTransactionId = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const transactionId = generateTransactionId();

  return {
    success: true,
    transactionId: transactionId,
  };
});

// Webhook handler for V2 callbacks
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  try {
    console.log("📞 V2 Payment webhook received:", req.body);

    // Extract authorization header and validate
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ success: false, error: "Missing authorization" });
    }

    // Validate webhook signature (implement according to PhonePe docs)
    // const expectedAuth = crypto.createHash('sha256').update('username:password').digest('hex');
    
    const event = req.body.event;
    const payload = req.body.payload;

    if (!event || !payload) {
      return res.status(400).json({ success: false, error: "Invalid webhook data" });
    }

    // Update order status based on event
    const merchantOrderId = payload.merchantOrderId;
    if (merchantOrderId) {
      let status = "pending";
      if (event === "checkout.order.completed" && payload.state === "COMPLETED") {
        status = "completed";
      } else if (event === "checkout.order.failed" && payload.state === "FAILED") {
        status = "failed";
      }

      await admin.firestore().collection("payment_requests").doc(merchantOrderId).update({
        webhookResponse: req.body,
        status: status,
        webhookReceivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    res.status(200).json({ success: true });
  } catch (error) {
    console.error("❌ Webhook error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});