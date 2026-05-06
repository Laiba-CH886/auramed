/**
 * Firebase Cloud Function:
 * When a new emergency_alerts document is created,
 * send FCM push notification to the doctor's saved tokens.
 */

const {setGlobalOptions, logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

exports.sendDoctorEmergencyAlert = onDocumentCreated(
  {
    document: "emergency_alerts/{alertId}",
    region: "us-central1",
  },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.error("No Firestore snapshot found in event.");
        return null;
      }

      const alertId = event.params.alertId;
      const alertData = snap.data();

      if (!alertData) {
        logger.error("Emergency alert document has no data.", {alertId});
        return null;
      }

      const doctorId = alertData.doctorId;
      const doctorName = alertData.doctorName || "Doctor";
      const patientName = alertData.patientName || "Patient";
      const consultationId = alertData.consultationId || "";
      const heartRate = alertData.heartRate ?? "--";
      const bp = alertData.bp ?? "--";
      const spo2 = alertData.spo2 ?? "--";
      const reasons = Array.isArray(alertData.reasons) ? alertData.reasons : [];
      const alreadySent = alertData.fcmSent === true;

      if (alreadySent) {
        logger.info("FCM already sent for this alert. Skipping.", {alertId});
        return null;
      }

      if (!doctorId) {
        logger.error("doctorId missing in emergency alert.", {alertId});
        return null;
      }

      const tokenSnap = await admin
        .firestore()
        .collection("users")
        .doc(doctorId)
        .collection("fcm_tokens")
        .get();

      if (tokenSnap.empty) {
        logger.warn("No FCM tokens found for doctor.", {doctorId, alertId});

        await admin.firestore().collection("emergency_alerts").doc(alertId).set(
          {
            fcmSent: false,
            fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
            fcmError: "No FCM tokens found for doctor",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );

        return null;
      }

      const tokens = tokenSnap.docs
        .map((doc) => doc.data().token)
        .filter((token) => typeof token === "string" && token.trim().length > 0);

      if (tokens.length === 0) {
        logger.warn("Doctor token documents exist, but token values are empty.", {
          doctorId,
          alertId,
        });

        await admin.firestore().collection("emergency_alerts").doc(alertId).set(
          {
            fcmSent: false,
            fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
            fcmError: "Doctor tokens were empty",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );

        return null;
      }

      const reasonText = reasons.length > 0 ? reasons.join(" • ") : "Abnormal vitals detected";

      const message = {
        notification: {
          title: `🚨 Emergency Alert for ${doctorName}`,
          body: `${patientName} | HR ${heartRate} | BP ${bp} | SpO₂ ${spo2}%`,
        },
        data: {
          type: "emergency_alert",
          alertId: String(alertId),
          consultationId: String(consultationId),
          doctorId: String(doctorId),
          doctorName: String(doctorName),
          patientName: String(patientName),
          heartRate: String(heartRate),
          bp: String(bp),
          spo2: String(spo2),
          reasons: reasonText,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "emergency_alerts",
            priority: "high",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      logger.info("Emergency FCM send result", {
        alertId,
        doctorId,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

      const invalidTokens = [];
      response.responses.forEach((resp, index) => {
        if (!resp.success) {
          logger.error("FCM send failure", {
            token: tokens[index],
            error: resp.error ? resp.error.message : "Unknown error",
          });

          const code = resp.error?.code || "";
          if (
            code.includes("registration-token-not-registered") ||
            code.includes("invalid-argument")
          ) {
            invalidTokens.push(tokens[index]);
          }
        }
      });

      for (const badToken of invalidTokens) {
        await admin
          .firestore()
          .collection("users")
          .doc(doctorId)
          .collection("fcm_tokens")
          .doc(badToken)
          .delete()
          .catch(() => null);
      }

      await admin.firestore().collection("emergency_alerts").doc(alertId).set(
        {
          fcmSent: response.successCount > 0,
          fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
          fcmSuccessCount: response.successCount,
          fcmFailureCount: response.failureCount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );

      return null;
    } catch (error) {
      logger.error("sendDoctorEmergencyAlert crashed", {
        error: error?.message || String(error),
      });

      try {
        const alertId = event?.params?.alertId;
        if (alertId) {
          await admin.firestore().collection("emergency_alerts").doc(alertId).set(
            {
              fcmSent: false,
              fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
              fcmError: error?.message || String(error),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
          );
        }
      } catch (_) {}

      return null;
    }
  }
);