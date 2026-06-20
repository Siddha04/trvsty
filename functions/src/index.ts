/**
 * Trusty backend Cloud Functions.
 *
 * Responsibilities that MUST live server-side (never in the mobile client):
 *   1. Creating Razorpay orders (requires the key secret).
 *   2. Verifying the Razorpay payment signature (HMAC-SHA256 with the secret).
 *   3. Handling Razorpay webhooks (the source of truth for capture/refund).
 *
 * Secrets are provided via the Firebase Functions runtime config / secrets:
 *   firebase functions:secrets:set RAZORPAY_KEY_ID
 *   firebase functions:secrets:set RAZORPAY_KEY_SECRET
 *   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
 */
import * as crypto from "crypto";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import Razorpay from "razorpay";

initializeApp();
const db = getFirestore();

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

/**
 * POST /createOrder
 * Body: { amount: number (paise), currency: "INR", userId: string }
 * Returns: { orderId: string }
 */
export const createOrder = onRequest(
  {secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET], cors: true},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }
    const {amount, currency = "INR", userId} = req.body ?? {};
    if (typeof amount !== "number" || amount <= 0 || !userId) {
      res.status(400).json({error: "Invalid order parameters"});
      return;
    }

    const instance = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });

    try {
      const order = await instance.orders.create({
        amount,
        currency,
        receipt: `trusty_${userId}_${Date.now()}`,
        notes: {userId},
      });
      res.json({orderId: order.id});
    } catch (err) {
      console.error("createOrder failed", err);
      res.status(500).json({error: "Could not create order"});
    }
  }
);

/**
 * POST /verifyPayment
 * Body: { razorpay_payment_id, razorpay_order_id, razorpay_signature }
 * Returns: { verified: boolean }
 */
export const verifyPayment = onRequest(
  {secrets: [RAZORPAY_KEY_SECRET], cors: true},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }
    const {
      razorpay_payment_id: paymentId,
      razorpay_order_id: orderId,
      razorpay_signature: signature,
    } = req.body ?? {};

    if (!paymentId || !orderId || !signature) {
      res.status(400).json({verified: false, error: "Missing fields"});
      return;
    }

    const expected = crypto
      .createHmac("sha256", RAZORPAY_KEY_SECRET.value())
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    // Constant-time comparison to avoid timing attacks.
    const verified =
      expected.length === signature.length &&
      crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));

    res.json({verified});
  }
);

/**
 * POST /razorpayWebhook
 * Razorpay calls this on payment.captured / payment.failed / refund events.
 * The X-Razorpay-Signature header is verified against the webhook secret.
 */
export const razorpayWebhook = onRequest(
  {secrets: [RAZORPAY_WEBHOOK_SECRET]},
  async (req, res) => {
    const signature = req.headers["x-razorpay-signature"] as string | undefined;
    const body = JSON.stringify(req.body);
    const expected = crypto
      .createHmac("sha256", RAZORPAY_WEBHOOK_SECRET.value())
      .update(body)
      .digest("hex");

    if (!signature || signature !== expected) {
      console.warn("Rejected webhook with invalid signature");
      res.status(400).send("invalid signature");
      return;
    }

    const event = req.body?.event as string;
    const payment = req.body?.payload?.payment?.entity;

    try {
      if (payment?.order_id) {
        const snap = await db
          .collection("payments")
          .where("razorpayOrderId", "==", payment.order_id)
          .limit(1)
          .get();
        if (!snap.empty) {
          const status =
            event === "payment.captured" ?
              "captured" :
              event === "payment.failed" ?
                "failed" :
                event === "refund.processed" ?
                  "refunded" :
                  "authorized";
          await snap.docs[0].ref.set(
            {
              status,
              razorpayPaymentId: payment.id,
              updatedAt: FieldValue.serverTimestamp(),
            },
            {merge: true}
          );
        }
      }
      res.status(200).send("ok");
    } catch (err) {
      console.error("Webhook processing failed", err);
      res.status(500).send("error");
    }
  }
);
