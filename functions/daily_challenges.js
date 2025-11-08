// Firebase Cloud Function to automatically generate daily challenges
// Place this in: functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Challenge pool organized by category
const challengePool = {
  recycling: [
    { title: 'Recycle all plastic waste generated today', points: 15, difficulty: 'medium', icon: '♻️' },
    { title: 'Separate and recycle paper, plastic, and glass', points: 20, difficulty: 'hard', icon: '🗑️' },
    { title: 'Clean and recycle 5 items before disposal', points: 10, difficulty: 'easy', icon: '🧼' },
    { title: 'Find a recycling center for electronic waste', points: 15, difficulty: 'medium', icon: '🔌' },
    { title: 'Compost your organic kitchen waste', points: 12, difficulty: 'easy', icon: '🌿' },
  ],
  transportation: [
    { title: 'Use public transport or cycle for one trip', points: 10, difficulty: 'easy', icon: '🚲' },
    { title: 'Walk or bike to your destination today', points: 15, difficulty: 'medium', icon: '🚶' },
    { title: 'Carpool with friends or colleagues', points: 12, difficulty: 'easy', icon: '🚗' },
    { title: 'Avoid using a car for the entire day', points: 25, difficulty: 'hard', icon: '🛑' },
    { title: 'Take stairs instead of elevator 3 times', points: 8, difficulty: 'easy', icon: '🪜' },
  ],
  consumption: [
    { title: 'Use a reusable water bottle instead of plastic', points: 10, difficulty: 'easy', icon: '💧' },
    { title: 'Bring your own shopping bag', points: 8, difficulty: 'easy', icon: '🛍️' },
    { title: 'Choose products with minimal packaging', points: 12, difficulty: 'medium', icon: '📦' },
    { title: 'Buy local or organic produce', points: 15, difficulty: 'medium', icon: '🥬' },
    { title: 'Avoid single-use plastics for the day', points: 20, difficulty: 'hard', icon: '🚫' },
    { title: 'Use a reusable coffee cup or mug', points: 10, difficulty: 'easy', icon: '☕' },
  ],
  energy: [
    { title: 'Turn off lights in unused rooms', points: 8, difficulty: 'easy', icon: '💡' },
    { title: 'Unplug devices when not in use', points: 10, difficulty: 'easy', icon: '🔌' },
    { title: 'Take a 5-minute shower to save water', points: 12, difficulty: 'medium', icon: '🚿' },
    { title: 'Air-dry clothes instead of using dryer', points: 15, difficulty: 'medium', icon: '👕' },
    { title: 'Use natural light instead of artificial lighting', points: 10, difficulty: 'easy', icon: '☀️' },
  ],
  awareness: [
    { title: 'Learn about one endangered species', points: 10, difficulty: 'easy', icon: '🐼' },
    { title: 'Share an eco-tip with 3 friends', points: 12, difficulty: 'medium', icon: '📢' },
    { title: 'Watch a documentary about sustainability', points: 15, difficulty: 'medium', icon: '📺' },
    { title: 'Research eco-friendly alternatives for daily products', points: 10, difficulty: 'easy', icon: '🔍' },
    { title: 'Join an online environmental community', points: 12, difficulty: 'easy', icon: '🌍' },
  ],
  food: [
    { title: 'Have one plant-based meal today', points: 12, difficulty: 'easy', icon: '🥗' },
    { title: 'Avoid food waste - finish all meals', points: 10, difficulty: 'easy', icon: '🍽️' },
    { title: 'Cook at home instead of ordering takeout', points: 15, difficulty: 'medium', icon: '👨‍🍳' },
    { title: 'Buy imperfect produce to reduce waste', points: 12, difficulty: 'easy', icon: '🥕' },
    { title: 'Meal prep to reduce packaging waste', points: 15, difficulty: 'medium', icon: '🍱' },
  ],
};

// Function to generate 2 unique challenges using date as seed
function generateDailyChallenges(date) {
  const allChallenges = [];
  
  // Flatten all challenges
  Object.entries(challengePool).forEach(([category, challenges]) => {
    challenges.forEach((challenge, index) => {
      allChallenges.push({
        id: `${category}_${index}`,
        ...challenge,
        category,
      });
    });
  });

  // Use date as seed for consistent daily challenges
  const seed = date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate();
  
  // Seeded shuffle
  const random = (seed) => {
    let x = Math.sin(seed) * 10000;
    return x - Math.floor(x);
  };
  
  for (let i = allChallenges.length - 1; i > 0; i--) {
    const j = Math.floor(random(seed + i) * (i + 1));
    [allChallenges[i], allChallenges[j]] = [allChallenges[j], allChallenges[i]];
  }

  return allChallenges.slice(0, 2);
}

// Scheduled function to run daily at midnight UTC
exports.generateDailyChallenges = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const today = new Date();
    const dateString = today.toISOString().split('T')[0];

    try {
      const challenges = generateDailyChallenges(today);
      
      await admin.firestore()
        .collection('challenges')
        .doc(dateString)
        .set({
          date: dateString,
          challenges: challenges,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ Successfully created challenges for ${dateString}`);
      return null;
    } catch (error) {
      console.error('❌ Error generating challenges:', error);
      throw error;
    }
  });

// HTTP function to manually generate challenges (for testing)
exports.manualGenerateChallenges = functions.https.onRequest(async (req, res) => {
  const today = new Date();
  const dateString = today.toISOString().split('T')[0];

  try {
    const challenges = generateDailyChallenges(today);
    
    await admin.firestore()
      .collection('challenges')
      .doc(dateString)
      .set({
        date: dateString,
        challenges: challenges,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    res.json({
      success: true,
      date: dateString,
      challenges: challenges,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Function to update user streak
exports.updateUserStreak = functions.firestore
  .document('user_challenges/{userChallengeId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Check if all challenges were just completed
    const wasAllCompleted = oldData.completed?.every(c => c) || false;
    const isAllCompleted = newData.completed?.every(c => c) || false;

    if (!wasAllCompleted && isAllCompleted) {
      // Extract userId from document ID (format: userId-date)
      const userId = context.params.userChallengeId.split('-')[0];

      try {
        const userRef = admin.firestore().collection('users').doc(userId);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
          const currentStreak = userDoc.data().streak || 0;
          await userRef.update({
            streak: currentStreak + 1,
          });
          console.log(`✅ Updated streak for user ${userId}: ${currentStreak + 1}`);
        }
      } catch (error) {
        console.error('❌ Error updating streak:', error);
      }
    }

    return null;
  });
