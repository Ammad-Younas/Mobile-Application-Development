const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// ✅ Cloud Function:  Send FCM when notification is added to fcm_queue
exports.sendFCMNotification = functions.firestore
  .document('fcm_queue/{queueId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    console.log('📩 New FCM request:', data);
    
    // Only process pending notifications
    if (data.status !== 'pending') {
      console.log('⏭️ Skipping non-pending notification');
      return null;
    }

    const message = {
      token: data.token,
      notification: {
        title: data. notification.title,
        body: data.notification.body,
      },
      data: data.data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'getcars_channel',
          priority: 'high',
        },
      },
      apns: {
        payload:  {
          aps: {
            sound: 'default',
            badge: 1,
            alert: {
              title: data. notification.title,
              body: data.notification.body,
            },
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('✅ FCM sent successfully:', response);
      
      // Mark as sent in Firestore
      await snap.ref.update({ 
        status: 'sent', 
        sentAt: admin.firestore. FieldValue.serverTimestamp(),
        messageId: response,
      });
      
      return response;
    } catch (error) {
      console.error('❌ Error sending FCM:', error);
      
      // Mark as failed
      await snap.ref.update({ 
        status: 'failed', 
        error: error.message,
        failedAt: admin.firestore. FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

// ✅ Clean up old fcm_queue documents (runs daily)
exports.cleanupFCMQueue = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7); // Delete items older than 7 days
    
    const snapshot = await admin.firestore()
      .collection('fcm_queue')
      .where('createdAt', '<', cutoffDate)
      .get();
    
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`🧹 Cleaned up ${snapshot. size} old FCM queue items`);
    
    return null;
  });