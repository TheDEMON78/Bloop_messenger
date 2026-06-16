const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.onNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const { conversationId } = event.params;

    if (!message || message.isDeleted) return;

    const db = getFirestore();

    // Get the conversation to find participants
    const convSnap = await db.collection("conversations").doc(conversationId).get();
    if (!convSnap.exists) return;

    const conv = convSnap.data();
    const senderId = message.senderId;
    const participants = conv.participants || [];

    // Get sender's display name
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName = senderSnap.exists
      ? senderSnap.data().displayName || "Bloop"
      : "Bloop";

    // Determine notification title
    const title = conv.isGroup
      ? `${conv.groupName || "Groupe"} · ${senderName}`
      : senderName;

    const body = message.isDeleted
      ? "Message supprimé"
      : message.content || "";

    // Send notification to all participants except the sender
    const recipients = participants.filter((uid) => uid !== senderId);

    const sendPromises = recipients.map(async (uid) => {
      const userSnap = await db.collection("users").doc(uid).get();
      if (!userSnap.exists) return;

      const fcmToken = userSnap.data().fcmToken;
      if (!fcmToken) return;

      try {
        await getMessaging().send({
          token: fcmToken,
          notification: { title, body },
          android: {
            priority: "high",
            notification: {
              channelId: "bloop_messages",
              sound: "default",
            },
          },
          data: {
            conversationId,
            senderId,
          },
        });
      } catch (err) {
        // Token stale — clean it up
        if (
          err.code === "messaging/registration-token-not-registered" ||
          err.code === "messaging/invalid-registration-token"
        ) {
          await db.collection("users").doc(uid).update({ fcmToken: null });
        }
      }
    });

    await Promise.all(sendPromises);
  }
);
