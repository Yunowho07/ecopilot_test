// Firebase Cloud Function for Daily Eco Tips Generation
// Deploy with: firebase deploy --only functions:generateDailyTips

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK (only once)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Comprehensive pool of eco-friendly tips organized by category
const tipPool = {
  waste_reduction: [
    { tip: 'Bring your own reusable bag when shopping 🛍️', emoji: '🛍️' },
    { tip: 'Use a reusable water bottle instead of single-use plastic 💧', emoji: '💧' },
    { tip: 'Say no to plastic straws - use metal or bamboo alternatives 🥤', emoji: '🥤' },
    { tip: 'Carry reusable cutlery to avoid disposable utensils 🍴', emoji: '🍴' },
    { tip: 'Use beeswax wraps instead of plastic wrap for food storage 🐝', emoji: '🐝' },
    { tip: 'Buy products with minimal or recyclable packaging 📦', emoji: '📦' },
    { tip: 'Refuse receipts when possible - go digital! 🧾', emoji: '🧾' },
    { tip: 'Use a reusable coffee cup for your daily brew ☕', emoji: '☕' },
    { tip: 'Donate old clothes instead of throwing them away 👕', emoji: '👕' },
    { tip: 'Compost food scraps to reduce landfill waste 🌱', emoji: '🌱' },
    { tip: 'Use cloth napkins instead of paper ones 🍽️', emoji: '🍽️' },
    { tip: 'Buy in bulk to reduce packaging waste 🏪', emoji: '🏪' },
    { tip: 'Repair items instead of replacing them 🔧', emoji: '🔧' },
  ],
  energy_saving: [
    { tip: 'Turn off lights when leaving a room 💡', emoji: '💡' },
    { tip: 'Unplug electronics when not in use to avoid phantom power 🔌', emoji: '🔌' },
    { tip: 'Use LED bulbs - they use 75% less energy than traditional bulbs 💡', emoji: '💡' },
    { tip: 'Set your thermostat 2 degrees lower in winter, higher in summer 🌡️', emoji: '🌡️' },
    { tip: 'Use natural light during the day instead of artificial lighting ☀️', emoji: '☀️' },
    { tip: 'Air dry clothes instead of using a dryer when possible 👔', emoji: '👔' },
    { tip: 'Take shorter showers to save hot water and energy 🚿', emoji: '🚿' },
    { tip: 'Use a laptop instead of a desktop - it uses less energy 💻', emoji: '💻' },
    { tip: 'Close curtains at night to keep heat in during winter 🏠', emoji: '🏠' },
    { tip: 'Use a power strip to easily turn off multiple devices at once ⚡', emoji: '⚡' },
    { tip: 'Run dishwashers and washing machines only when full 🧺', emoji: '🧺' },
    { tip: 'Use cold water for laundry - it saves energy and protects colors 🌊', emoji: '🌊' },
    { tip: 'Keep your refrigerator between 37-40°F for optimal efficiency ❄️', emoji: '❄️' },
  ],
  sustainable_shopping: [
    { tip: 'Choose products made from recycled materials ♻️', emoji: '♻️' },
    { tip: 'Buy local produce to reduce carbon footprint from transport 🥕', emoji: '🥕' },
    { tip: 'Support eco-friendly and certified sustainable brands 🌿', emoji: '🌿' },
    { tip: 'Choose products with Forest Stewardship Council (FSC) certification 🌲', emoji: '🌲' },
    { tip: 'Buy second-hand items when possible - reduce, reuse! 🏷️', emoji: '🏷️' },
    { tip: 'Avoid fast fashion - choose quality over quantity 👗', emoji: '👗' },
    { tip: 'Look for cruelty-free and vegan product certifications 🐰', emoji: '🐰' },
    { tip: 'Choose products without palm oil to protect rainforests 🌴', emoji: '🌴' },
    { tip: 'Buy organic when possible to reduce pesticide use 🍎', emoji: '🍎' },
    { tip: 'Support businesses with transparent supply chains 🔍', emoji: '🔍' },
    { tip: 'Choose refillable products over single-use ones 🔄', emoji: '🔄' },
    { tip: 'Shop at farmers markets for fresh, local goods 🧺', emoji: '🧺' },
  ],
  transportation: [
    { tip: 'Walk or bike for short trips instead of driving 🚶', emoji: '🚶' },
    { tip: 'Use public transportation when possible 🚌', emoji: '🚌' },
    { tip: 'Carpool with colleagues or friends to reduce emissions 🚗', emoji: '🚗' },
    { tip: 'Plan your errands to minimize driving distance 🗺️', emoji: '🗺️' },
    { tip: 'Keep your car tires properly inflated for better fuel efficiency 🛞', emoji: '🛞' },
    { tip: 'Consider an electric or hybrid vehicle for your next car 🔋', emoji: '🔋' },
    { tip: 'Work from home when possible to eliminate commute emissions 🏡', emoji: '🏡' },
    { tip: 'Combine trips to reduce overall vehicle use 📍', emoji: '📍' },
    { tip: 'Use bike-sharing or scooter-sharing services 🛴', emoji: '🛴' },
    { tip: 'Avoid idling your car - turn it off if waiting more than 30 seconds 🚦', emoji: '🚦' },
  ],
  food_habits: [
    { tip: 'Eat more plant-based meals to reduce your carbon footprint 🥗', emoji: '🥗' },
    { tip: 'Reduce food waste by meal planning 📝', emoji: '📝' },
    { tip: 'Store food properly to extend its shelf life 🥫', emoji: '🥫' },
    { tip: 'Use leftovers creatively instead of throwing them away 🍲', emoji: '🍲' },
    { tip: 'Buy imperfect produce - it tastes the same and reduces waste 🥔', emoji: '🥔' },
    { tip: 'Freeze food before it spoils to use later ❄️', emoji: '❄️' },
    { tip: 'Choose seasonal produce - it\'s fresher and more sustainable 🍓', emoji: '🍓' },
    { tip: 'Start a small herb garden at home 🌿', emoji: '🌿' },
    { tip: 'Bring reusable containers for restaurant leftovers 📦', emoji: '📦' },
    { tip: 'Support sustainable fishing by choosing certified seafood 🐟', emoji: '🐟' },
    { tip: 'Reduce meat consumption - try Meatless Mondays 🥦', emoji: '🥦' },
  ],
  water_conservation: [
    { tip: 'Fix leaky faucets - a drip can waste gallons per day 💧', emoji: '💧' },
    { tip: 'Turn off the tap while brushing your teeth 🪥', emoji: '🪥' },
    { tip: 'Collect rainwater for watering plants 🌧️', emoji: '🌧️' },
    { tip: 'Use a broom instead of a hose to clean driveways 🧹', emoji: '🧹' },
    { tip: 'Install low-flow showerheads to reduce water use 🚿', emoji: '🚿' },
    { tip: 'Water plants in the morning or evening to reduce evaporation 🌱', emoji: '🌱' },
    { tip: 'Use a dishwasher instead of hand washing - it uses less water 🍽️', emoji: '🍽️' },
    { tip: 'Choose drought-resistant plants for your garden 🌵', emoji: '🌵' },
    { tip: 'Reuse pasta or vegetable cooking water for plants 🍝', emoji: '🍝' },
    { tip: 'Take a bucket shower and use the water for cleaning 🪣', emoji: '🪣' },
  ],
  recycling: [
    { tip: 'Rinse containers before recycling to avoid contamination ♻️', emoji: '♻️' },
    { tip: 'Know your local recycling rules - not all plastics are accepted 🔍', emoji: '🔍' },
    { tip: 'Remove caps and lids from bottles before recycling 🧴', emoji: '🧴' },
    { tip: 'Recycle electronics properly at designated e-waste centers 📱', emoji: '📱' },
    { tip: 'Flatten cardboard boxes to save space in recycling bins 📦', emoji: '📦' },
    { tip: 'Recycle batteries at special collection points 🔋', emoji: '🔋' },
    { tip: 'Don\'t bag recyclables - keep them loose in the bin 🗑️', emoji: '🗑️' },
    { tip: 'Recycle glass bottles and jars - they can be recycled infinitely 🍾', emoji: '🍾' },
    { tip: 'Shred paper documents before recycling for security 📄', emoji: '📄' },
    { tip: 'Check product labels for recycling symbols and instructions ♻️', emoji: '♻️' },
  ],
  eco_habits: [
    { tip: 'Use digital documents instead of printing when possible 📱', emoji: '📱' },
    { tip: 'Choose eco-friendly cleaning products 🧽', emoji: '🧽' },
    { tip: 'Plant a tree or support reforestation projects 🌳', emoji: '🌳' },
    { tip: 'Educate others about sustainable living 📚', emoji: '📚' },
    { tip: 'Join local environmental cleanup events 🧹', emoji: '🧹' },
    { tip: 'Support environmental organizations and causes 💚', emoji: '💚' },
    { tip: 'Use reusable batteries or rechargeable ones 🔋', emoji: '🔋' },
    { tip: 'Avoid single-use items whenever possible 🚫', emoji: '🚫' },
    { tip: 'Choose bar soap over liquid soap to reduce plastic 🧼', emoji: '🧼' },
    { tip: 'Use a reusable lunch box instead of disposable bags 🍱', emoji: '🍱' },
    { tip: 'Switch to eco-friendly menstrual products 🌸', emoji: '🌸' },
    { tip: 'Make your own cleaning products with natural ingredients 🍋', emoji: '🍋' },
    { tip: 'Participate in citizen science projects for the environment 🔬', emoji: '🔬' },
    { tip: 'Use a bamboo toothbrush instead of plastic 🪥', emoji: '🪥' },
    { tip: 'Vote for politicians who prioritize environmental policies 🗳️', emoji: '🗳️' },
  ],
};

/**
 * Generate a daily tip for a specific date using date-seeded randomization
 */
function generateDailyTip(date) {
  // Flatten all tips into a single array
  const allTips = [];
  Object.keys(tipPool).forEach((category) => {
    tipPool[category].forEach((tipData) => {
      allTips.push({
        ...tipData,
        category,
      });
    });
  });

  // Use date as seed for consistent random selection
  // Format: YYYYMMDD (e.g., 20251109)
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const seed = parseInt(year + month + day);
  
  // Simple seeded random using modulo
  const index = seed % allTips.length;
  const selectedTip = allTips[index];

  // Format date as YYYY-MM-DD
  const dateString = `${year}-${month}-${day}`;

  return {
    tip: selectedTip.tip,
    category: selectedTip.category,
    emoji: selectedTip.emoji,
    date: dateString,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Scheduled Cloud Function: Generate daily tip at midnight UTC
 * Runs automatically every day at 00:00 UTC
 */
exports.generateDailyTips = functions.pubsub
  .schedule('0 0 * * *') // Every day at midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const today = new Date();
    const tip = generateDailyTip(today);

    try {
      await admin.firestore()
        .collection('daily_tips')
        .doc(tip.date)
        .set(tip, { merge: true });

      console.log(`✅ Generated daily tip for ${tip.date}`);
      return { success: true, date: tip.date };
    } catch (error) {
      console.error('❌ Error generating daily tip:', error);
      throw new functions.https.HttpsError('internal', 'Failed to generate tip');
    }
  });

/**
 * HTTP Function: Manually trigger tip generation
 * Useful for testing and initialization
 * Call with: https://REGION-PROJECT.cloudfunctions.net/manualGenerateTip?days=7
 */
exports.manualGenerateTip = functions.https.onRequest(async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 1;
    const today = new Date();
    const results = [];

    for (let i = 0; i < days; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      
      const tip = generateDailyTip(date);
      
      await admin.firestore()
        .collection('daily_tips')
        .doc(tip.date)
        .set(tip, { merge: true });

      results.push({
        date: tip.date,
        tip: tip.tip,
        category: tip.category,
      });
    }

    res.status(200).json({
      success: true,
      message: `Generated ${days} daily tips`,
      tips: results,
    });
  } catch (error) {
    console.error('Error in manual tip generation:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * HTTP Function: Get all tips in the pool (for debugging)
 */
exports.getAllTips = functions.https.onRequest((req, res) => {
  const stats = {
    totalCategories: Object.keys(tipPool).length,
    categoryCounts: {},
    totalTips: 0,
  };

  Object.keys(tipPool).forEach((category) => {
    const count = tipPool[category].length;
    stats.categoryCounts[category] = count;
    stats.totalTips += count;
  });

  res.status(200).json({
    success: true,
    stats,
    tipPool,
  });
});
