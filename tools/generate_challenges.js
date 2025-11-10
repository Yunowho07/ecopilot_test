/**
 * Script to manually generate daily challenges in Firestore
 * 
 * Usage:
 * 1. Make sure you have firebase-admin installed:
 *    npm install firebase-admin
 * 
 * 2. Download your Firebase service account key from Firebase Console:
 *    Project Settings > Service Accounts > Generate New Private Key
 *    Save it as serviceAccountKey.json in the same directory
 * 
 * 3. Run this script:
 *    node generate_challenges.js
 * 
 * This will generate challenges for today and the next 7 days
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

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

// Generate challenges for today and next 7 days
async function generateChallengesForDays(numDays = 8) {
  console.log(`\n🚀 Generating challenges for ${numDays} days...\n`);
  
  const batch = db.batch();
  const generatedDates = [];
  
  for (let i = 0; i < numDays; i++) {
    const date = new Date();
    date.setDate(date.getDate() + i);
    const dateString = date.toISOString().split('T')[0];
    
    const challenges = generateDailyChallenges(date);
    
    const docRef = db.collection('challenges').doc(dateString);
    batch.set(docRef, {
      date: dateString,
      challenges: challenges,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    generatedDates.push({
      date: dateString,
      challenges: challenges.map(c => ({ title: c.title, points: c.points })),
    });
  }
  
  await batch.commit();
  
  console.log('✅ Successfully generated challenges!\n');
  
  generatedDates.forEach(({ date, challenges }) => {
    console.log(`📅 ${date}:`);
    challenges.forEach(({ title, points }, idx) => {
      console.log(`   ${idx + 1}. ${title} (+${points} pts)`);
    });
    console.log('');
  });
  
  console.log('✅ All challenges saved to Firestore!\n');
  
  process.exit(0);
}

// Run the generator
generateChallengesForDays(8).catch((error) => {
  console.error('❌ Error generating challenges:', error);
  process.exit(1);
});
