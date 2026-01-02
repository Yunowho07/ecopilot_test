// Firebase Cloud Functions for Streak Reminder System
// Handles server-triggered push notifications for streak management

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Scheduled function to check user streaks and send reminders
 * Runs every day at 9:00 PM to warn users who haven't completed today's challenge
 */
exports.checkStreaksAndSendReminders = functions.pubsub
  .schedule('0 21 * * *') // 9:00 PM UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🔔 Starting streak reminder check...');
    
    const today = new Date().toISOString().split('T')[0];
    const db = admin.firestore();
    
    try {
      // Get all users with FCM tokens
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .get();
      
      if (usersSnapshot.empty) {
        console.log('No users with FCM tokens found');
        return null;
      }
      
      let remindersSent = 0;
      const promises = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        const currentStreak = userData.streak || 0;
        
        // Check if user has completed today's challenge
        const challengeDoc = await db.collection('user_challenges')
          .doc(`${userId}-${today}`)
          .get();
        
        const hasCompletedToday = challengeDoc.exists && 
          (challengeDoc.data().completed || []).every(c => c === true);
        
        if (!hasCompletedToday && currentStreak > 0) {
          // User has an active streak but hasn't completed today's challenge
          const message = buildStreakWarningMessage(currentStreak);
          
          promises.push(
            sendPushNotification(fcmToken, message)
              .then(() => {
                remindersSent++;
                console.log(`✅ Reminder sent to user ${userId} (streak: ${currentStreak})`);
              })
              .catch(error => {
                console.error(`❌ Failed to send reminder to ${userId}:`, error);
              })
          );
        }
      }
      
      await Promise.all(promises);
      console.log(`🔔 Sent ${remindersSent} streak reminder(s)`);
      
      return null;
    } catch (error) {
      console.error('❌ Error in checkStreaksAndSendReminders:', error);
      throw error;
    }
  });

/**
 * Check for inactive users and send re-engagement notifications
 * Runs daily at 10:00 AM UTC
 */
exports.sendReEngagementNotifications = functions.pubsub
  .schedule('0 10 * * *') // 10:00 AM UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🔄 Starting re-engagement check...');
    
    const db = admin.firestore();
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    const threeDaysAgoStr = threeDaysAgo.toISOString().split('T')[0];
    
    try {
      // Find users who haven't completed challenges in 3+ days
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .get();
      
      let notificationsSent = 0;
      const promises = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        const lastChallengeDate = userData.lastChallengeDate;
        
        // Check if user has been inactive for 3+ days
        if (!lastChallengeDate || lastChallengeDate < threeDaysAgoStr) {
          const oldStreak = userData.streak || 0;
          const message = buildReEngagementMessage(oldStreak);
          
          promises.push(
            sendPushNotification(fcmToken, message)
              .then(() => {
                notificationsSent++;
                console.log(`✅ Re-engagement sent to inactive user ${userId}`);
              })
              .catch(error => {
                console.error(`❌ Failed to send re-engagement to ${userId}:`, error);
              })
          );
        }
      }
      
      await Promise.all(promises);
      console.log(`🔄 Sent ${notificationsSent} re-engagement notification(s)`);
      
      return null;
    } catch (error) {
      console.error('❌ Error in sendReEngagementNotifications:', error);
      throw error;
    }
  });

/**
 * Firestore trigger: Send milestone celebration when user reaches special streak
 */
exports.sendMilestoneNotification = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    const oldStreak = beforeData.streak || 0;
    const newStreak = afterData.streak || 0;
    
    // Check if this is a milestone (7, 14, 30, 50, 100, 200 days)
    const milestones = [7, 14, 30, 50, 100, 200];
    
    if (newStreak > oldStreak && milestones.includes(newStreak)) {
      const fcmToken = afterData.fcmToken;
      
      if (fcmToken) {
        const message = buildMilestoneMessage(newStreak);
        
        try {
          await sendPushNotification(fcmToken, message);
          console.log(`🎉 Milestone notification sent to ${userId} for ${newStreak}-day streak`);
        } catch (error) {
          console.error(`❌ Failed to send milestone notification to ${userId}:`, error);
        }
      }
    }
    
    return null;
  });

/**
 * HTTP function: Manually trigger streak check (for testing)
 */
exports.manualStreakCheck = functions.https.onRequest(async (req, res) => {
  const userId = req.query.userId;
  
  if (!userId) {
    res.status(400).json({ error: 'userId parameter required' });
    return;
  }
  
  const today = new Date().toISOString().split('T')[0];
  const db = admin.firestore();
  
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    const currentStreak = userData.streak || 0;
    
    if (!fcmToken) {
      res.status(400).json({ error: 'User has no FCM token' });
      return;
    }
    
    // Check today's challenge completion
    const challengeDoc = await db.collection('user_challenges')
      .doc(`${userId}-${today}`)
      .get();
    
    const hasCompletedToday = challengeDoc.exists && 
      (challengeDoc.data().completed || []).every(c => c === true);
    
    if (!hasCompletedToday) {
      const message = buildStreakWarningMessage(currentStreak);
      await sendPushNotification(fcmToken, message);
      
      res.json({
        success: true,
        message: 'Streak warning sent',
        streak: currentStreak,
        completedToday: false
      });
    } else {
      res.json({
        success: true,
        message: 'Challenge already completed today',
        streak: currentStreak,
        completedToday: true
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============= Helper Functions =============

/**
 * Build streak warning message based on current streak
 */
function buildStreakWarningMessage(streak) {
  let title, body;
  
  if (streak === 0) {
    title = '🌱 Start Your Eco Journey';
    body = 'Complete your first daily challenge and begin your streak!';
  } else if (streak === 1) {
    title = '⚠️ Don\'t Lose Your Streak!';
    body = 'Your 1-day streak is waiting! Complete today\'s challenge now!';
  } else if (streak < 7) {
    title = '🔥 Your Streak Is At Risk!';
    body = `Don't lose your ${streak}-day streak! You have until midnight to complete today's challenge!`;
  } else if (streak < 30) {
    title = '🚨 URGENT: Streak Warning!';
    body = `Your amazing ${streak}-day streak is about to end! Take action now!`;
  } else {
    title = '👑 LEGENDARY STREAK AT RISK!';
    body = `Don't let your epic ${streak}-day streak die! You've come so far - finish today's challenge!`;
  }
  
  return {
    notification: { title, body },
    data: {
      type: 'streak_warning',
      streak: streak.toString(),
      clickAction: 'FLUTTER_NOTIFICATION_CLICK'
    }
  };
}

/**
 * Build milestone celebration message
 */
function buildMilestoneMessage(streak) {
  let title, body;
  
  switch (streak) {
    case 7:
      title = '🔥 7-Day Streak Milestone!';
      body = 'One week of eco-consciousness! You\'re building an amazing habit!';
      break;
    case 14:
      title = '🌟 2-Week Streak Achieved!';
      body = 'Two weeks strong! You\'re making a real environmental impact!';
      break;
    case 30:
      title = '🏆 1-Month Streak Champion!';
      body = 'A full month! You\'re officially an eco champion! Keep going!';
      break;
    case 50:
      title = '💎 50-Day Streak Legend!';
      body = '50 days of consistency! You\'re absolutely unstoppable!';
      break;
    case 100:
      title = '👑 100-DAY STREAK MASTERY!';
      body = 'LEGENDARY! 100 days of dedication! You\'re inspiring the planet!';
      break;
    case 200:
      title = '🌍 200-DAY WORLD-CLASS STREAK!';
      body = 'PHENOMENAL! 200 days! You\'re a true eco warrior and role model!';
      break;
    default:
      title = `🎉 ${streak}-Day Streak!`;
      body = 'Keep up the incredible work!';
  }
  
  return {
    notification: { title, body },
    data: {
      type: 'streak_milestone',
      streak: streak.toString(),
      clickAction: 'FLUTTER_NOTIFICATION_CLICK'
    }
  };
}

/**
 * Build re-engagement message for inactive users
 */
function buildReEngagementMessage(oldStreak) {
  let title, body;
  
  if (oldStreak === 0) {
    title = '🌱 Ready to Start?';
    body = 'Begin your eco journey today! Complete your first daily challenge and earn points!';
  } else if (oldStreak < 7) {
    title = '💚 We Miss You!';
    body = `You had a ${oldStreak}-day streak going! Come back and restart your eco journey!`;
  } else {
    title = '🔥 Your ${oldStreak}-Day Streak Awaits!';
    body = 'You were doing amazing! Come back and rebuild your streak - the planet needs you!';
  }
  
  return {
    notification: { title, body },
    data: {
      type: 're_engagement',
      oldStreak: oldStreak.toString(),
      clickAction: 'FLUTTER_NOTIFICATION_CLICK'
    }
  };
}

/**
 * Send push notification via FCM
 */
async function sendPushNotification(fcmToken, message) {
  try {
    const response = await admin.messaging().send({
      token: fcmToken,
      notification: message.notification,
      data: message.data,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'ecopilot_streak_reminders'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    });
    
    return response;
  } catch (error) {
    // Handle invalid FCM token
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.warn(`Invalid FCM token, should remove from database: ${fcmToken}`);
    }
    throw error;
  }
}
