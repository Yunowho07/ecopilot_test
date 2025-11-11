const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * DYNAMIC NOTIFICATION CLOUD FUNCTIONS
 * Auto-trigger notifications based on user activity and system events
 */

// ========================================
// 1. STREAK MILESTONE NOTIFICATION
// ========================================
exports.onStreakMilestone = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const before = change.before.data();
    const after = change.after.data();

    const oldStreak = before.streak || 0;
    const newStreak = after.streak || 0;

    // Check if streak increased and hit milestone (multiples of 5, 7, 10, 30, etc.)
    const milestones = [3, 5, 7, 10, 14, 21, 30, 50, 100];
    const hitMilestone = milestones.includes(newStreak) && newStreak > oldStreak;

    if (hitMilestone) {
      let badge = '';
      let title = '';
      
      if (newStreak === 3) {
        badge = '🌱 Green Starter';
        title = '3-Day Streak!';
      } else if (newStreak === 7) {
        badge = '🔥 Week Warrior';
        title = '7-Day Streak!';
      } else if (newStreak === 30) {
        badge = '🏆 Eco Champion';
        title = '30-Day Streak!';
      } else if (newStreak === 100) {
        badge = '👑 Eco Legend';
        title = '100-Day Streak!';
      } else {
        badge = `🌟 ${newStreak}-Day Streak`;
        title = `${newStreak}-Day Streak!`;
      }

      const body = `🎉 Amazing! You've earned the "${badge}" badge. Keep going!`;

      // Create notification in Firestore
      await db.collection('notifications').add({
        userId: userId,
        title: title,
        body: body,
        category: 'milestone',
        data: {
          streak: newStreak,
          badge: badge,
        },
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
      });

      // Send push notification if user has FCM token
      if (after.fcmToken) {
        try {
          await messaging.send({
            token: after.fcmToken,
            notification: {
              title: title,
              body: body,
            },
            data: {
              category: 'milestone',
              streak: String(newStreak),
              badge: badge,
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'ecopilot_dynamic',
                color: '#4CAF50',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          });

          console.log(`✅ Streak milestone notification sent to user ${userId}`);
        } catch (error) {
          console.error(`❌ Error sending push notification: ${error}`);
        }
      }
    }
  });

// ========================================
// 2. ECO POINTS MILESTONE NOTIFICATION
// ========================================
exports.onPointsMilestone = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const before = change.before.data();
    const after = change.after.data();

    const oldPoints = before.ecoPoints || 0;
    const newPoints = after.ecoPoints || 0;

    // Check if points hit milestone (100, 250, 500, 1000, etc.)
    const milestones = [100, 250, 500, 750, 1000, 2500, 5000, 10000];
    
    for (const milestone of milestones) {
      if (oldPoints < milestone && newPoints >= milestone) {
        const title = `${milestone} Points Milestone! 🎯`;
        const body = `🌟 Incredible! You've reached ${milestone} EcoPoints. You're making a real difference!`;

        await db.collection('notifications').add({
          userId: userId,
          title: title,
          body: body,
          category: 'milestone',
          data: {
            points: newPoints,
            milestone: milestone,
          },
          read: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: new Date().toISOString(),
        });

        if (after.fcmToken) {
          try {
            await messaging.send({
              token: after.fcmToken,
              notification: { title, body },
              data: {
                category: 'milestone',
                points: String(newPoints),
              },
            });
          } catch (error) {
            console.error(`Error sending push: ${error}`);
          }
        }

        break; // Only send one notification per update
      }
    }
  });

// ========================================
// 3. SCANNED PRODUCT INSIGHT NOTIFICATION
// ========================================
exports.onProductScanned = functions.firestore
  .document('users/{userId}/scannedProducts/{productId}')
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const productData = snapshot.data();
    
    const ecoScore = productData.ecoScore || 0;
    const productName = productData.productName || productData.name || 'Product';

    let title = '';
    let body = '';

    if (ecoScore >= 80) {
      title = 'Excellent Choice! 🌟';
      body = `${productName} has a fantastic eco-score of ${ecoScore}/100! You're making sustainable choices!`;
    } else if (ecoScore >= 60) {
      title = 'Good Pick! ✅';
      body = `${productName} scored ${ecoScore}/100. Check out eco-friendly alternatives to score higher!`;
    } else if (ecoScore >= 40) {
      title = 'Room for Improvement 💡';
      body = `${productName} scored ${ecoScore}/100. Consider greener options for a better planet!`;
    } else {
      title = 'Low Eco-Score ⚠️';
      body = `${productName} has an eco-score of ${ecoScore}/100. Let's find a more sustainable alternative!`;
    }

    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    await db.collection('notifications').add({
      userId: userId,
      title: title,
      body: body,
      category: 'scan_insight',
      data: {
        productName: productName,
        ecoScore: ecoScore,
        productId: snapshot.id,
      },
      read: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: new Date().toISOString(),
    });

    if (userData && userData.fcmToken) {
      try {
        await messaging.send({
          token: userData.fcmToken,
          notification: { title, body },
          data: {
            category: 'scan_insight',
            ecoScore: String(ecoScore),
          },
        });
      } catch (error) {
        console.error(`Error sending scan notification: ${error}`);
      }
    }
  });

// ========================================
// 4. DAILY CHALLENGE REMINDER
// ========================================
exports.sendDailyChallengeReminder = functions.pubsub
  .schedule('every day 08:00')
  .timeZone('America/New_York') // Adjust to your timezone
  .onRun(async (context) => {
    console.log('⏰ Sending daily challenge reminders...');

    // Get all users with FCM tokens
    const usersSnapshot = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    const promises = [];

    usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const userId = userDoc.id;

      // Create Firestore notification
      promises.push(
        db.collection('notifications').add({
          userId: userId,
          title: 'Today\'s Eco Challenge! 🌞',
          body: 'Good morning! Complete today\'s eco challenge and earn bonus points!',
          category: 'daily_challenge',
          data: {
            type: 'reminder',
          },
          read: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: new Date().toISOString(),
        })
      );

      // Send push notification
      if (userData.fcmToken) {
        promises.push(
          messaging.send({
            token: userData.fcmToken,
            notification: {
              title: 'Today\'s Eco Challenge! 🌞',
              body: 'Complete today\'s challenge and earn +20 points!',
            },
            data: {
              category: 'daily_challenge',
            },
          }).catch((error) => {
            console.error(`Error sending to ${userId}: ${error}`);
          })
        );
      }
    });

    await Promise.all(promises);
    console.log(`✅ Sent daily challenge reminders to ${usersSnapshot.size} users`);
  });

// ========================================
// 5. ECO TIP OF THE DAY
// ========================================
exports.sendDailyEcoTip = functions.pubsub
  .schedule('every day 12:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('💡 Sending daily eco tips...');

    const tips = [
      '♻️ Bring your own reusable bag when shopping to reduce plastic waste!',
      '💡 Switch to LED bulbs - they use 75% less energy than traditional bulbs!',
      '🚰 Fix leaky faucets to save up to 3,000 gallons of water per year!',
      '🌱 Start composting kitchen scraps to reduce landfill waste by 30%!',
      '🚲 Bike or walk for short trips instead of driving to reduce emissions!',
      '☕ Use a reusable water bottle - save 167 plastic bottles per year!',
      '🌍 Buy local produce to reduce transportation emissions!',
      '🔌 Unplug electronics when not in use to cut phantom power consumption!',
      '🌿 Plant a tree - it absorbs 48 lbs of CO₂ per year!',
      '📦 Recycle cardboard boxes - saves 9 cubic yards of landfill space!',
    ];

    const todayTip = tips[Math.floor(Math.random() * tips.length)];

    const usersSnapshot = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    const promises = [];

    usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const userId = userDoc.id;

      promises.push(
        db.collection('notifications').add({
          userId: userId,
          title: 'Eco Tip of the Day 💡',
          body: todayTip,
          category: 'eco_tip',
          data: {
            tip: todayTip,
          },
          read: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: new Date().toISOString(),
        })
      );

      if (userData.fcmToken) {
        promises.push(
          messaging.send({
            token: userData.fcmToken,
            notification: {
              title: 'Eco Tip of the Day 💡',
              body: todayTip,
            },
            data: {
              category: 'eco_tip',
            },
          }).catch((error) => {
            console.error(`Error sending tip to ${userId}: ${error}`);
          })
        );
      }
    });

    await Promise.all(promises);
    console.log(`✅ Sent eco tips to ${usersSnapshot.size} users`);
  });

// ========================================
// 6. NEW RANK ACHIEVEMENT
// ========================================
exports.onRankUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const before = change.before.data();
    const after = change.after.data();

    const oldRank = before.title || 'Green Beginner';
    const newRank = after.title || 'Green Beginner';

    if (oldRank !== newRank) {
      const title = 'Rank Up! 🎖️';
      const body = `Congratulations! You've advanced to ${newRank}! Keep up the amazing work!`;

      await db.collection('notifications').add({
        userId: userId,
        title: title,
        body: body,
        category: 'milestone',
        data: {
          oldRank: oldRank,
          newRank: newRank,
        },
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
      });

      if (after.fcmToken) {
        try {
          await messaging.send({
            token: after.fcmToken,
            notification: { title, body },
            data: {
              category: 'milestone',
              rank: newRank,
            },
          });
        } catch (error) {
          console.error(`Error sending rank notification: ${error}`);
        }
      }
    }
  });

// ========================================
// 7. BROADCAST NOTIFICATION TO ALL USERS
// ========================================
exports.sendBroadcastNotification = functions.https.onCall(async (data, context) => {
  // Only allow admin users to broadcast (add your admin UID check here)
  // if (!context.auth || context.auth.uid !== 'YOUR_ADMIN_UID') {
  //   throw new functions.https.HttpsError('permission-denied', 'Only admins can broadcast');
  // }

  const { title, body, category } = data;

  const usersSnapshot = await db.collection('users')
    .where('fcmToken', '!=', null)
    .get();

  const promises = [];

  usersSnapshot.forEach((userDoc) => {
    const userData = userDoc.data();
    const userId = userDoc.id;

    promises.push(
      db.collection('notifications').add({
        userId: userId,
        title: title,
        body: body,
        category: category || 'general',
        data: {},
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
      })
    );

    if (userData.fcmToken) {
      promises.push(
        messaging.send({
          token: userData.fcmToken,
          notification: { title, body },
          data: { category: category || 'general' },
        }).catch((error) => {
          console.error(`Error: ${error}`);
        })
      );
    }
  });

  await Promise.all(promises);
  return { success: true, sentTo: usersSnapshot.size };
});
