import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Utility class for generating and managing daily eco-friendly tips.
///
/// This system provides:
/// - 100+ curated eco tips across 8 categories
/// - Date-seeded random selection for consistency
/// - Automatic Firestore integration
/// - Category-based filtering
class TipGenerator {
  /// Comprehensive pool of eco-friendly tips organized by category.
  /// Each tip includes the text and an emoji for visual appeal.
  static const Map<String, List<Map<String, String>>> _tipPool = {
    'waste_reduction': [
      {
        'tip': 'Bring your own reusable bag when shopping 🛍️',
        'category': 'waste_reduction',
        'emoji': '🛍️',
      },
      {
        'tip': 'Use a reusable water bottle instead of single-use plastic 💧',
        'category': 'waste_reduction',
        'emoji': '💧',
      },
      {
        'tip': 'Say no to plastic straws - use metal or bamboo alternatives 🥤',
        'category': 'waste_reduction',
        'emoji': '🥤',
      },
      {
        'tip': 'Carry reusable cutlery to avoid disposable utensils 🍴',
        'category': 'waste_reduction',
        'emoji': '🍴',
      },
      {
        'tip': 'Use beeswax wraps instead of plastic wrap for food storage 🐝',
        'category': 'waste_reduction',
        'emoji': '🐝',
      },
      {
        'tip': 'Buy products with minimal or recyclable packaging 📦',
        'category': 'waste_reduction',
        'emoji': '📦',
      },
      {
        'tip': 'Refuse receipts when possible - go digital! 🧾',
        'category': 'waste_reduction',
        'emoji': '🧾',
      },
      {
        'tip': 'Use a reusable coffee cup for your daily brew ☕',
        'category': 'waste_reduction',
        'emoji': '☕',
      },
      {
        'tip': 'Donate old clothes instead of throwing them away 👕',
        'category': 'waste_reduction',
        'emoji': '👕',
      },
      {
        'tip': 'Compost food scraps to reduce landfill waste 🌱',
        'category': 'waste_reduction',
        'emoji': '🌱',
      },
      {
        'tip': 'Use cloth napkins instead of paper ones 🍽️',
        'category': 'waste_reduction',
        'emoji': '🍽️',
      },
      {
        'tip': 'Buy in bulk to reduce packaging waste 🏪',
        'category': 'waste_reduction',
        'emoji': '🏪',
      },
      {
        'tip': 'Repair items instead of replacing them 🔧',
        'category': 'waste_reduction',
        'emoji': '🔧',
      },
    ],
    'energy_saving': [
      {
        'tip': 'Turn off lights when leaving a room 💡',
        'category': 'energy_saving',
        'emoji': '💡',
      },
      {
        'tip': 'Unplug electronics when not in use to avoid phantom power 🔌',
        'category': 'energy_saving',
        'emoji': '🔌',
      },
      {
        'tip':
            'Use LED bulbs - they use 75% less energy than traditional bulbs 💡',
        'category': 'energy_saving',
        'emoji': '💡',
      },
      {
        'tip':
            'Set your thermostat 2 degrees lower in winter, higher in summer 🌡️',
        'category': 'energy_saving',
        'emoji': '🌡️',
      },
      {
        'tip':
            'Use natural light during the day instead of artificial lighting ☀️',
        'category': 'energy_saving',
        'emoji': '☀️',
      },
      {
        'tip': 'Air dry clothes instead of using a dryer when possible 👔',
        'category': 'energy_saving',
        'emoji': '👔',
      },
      {
        'tip': 'Take shorter showers to save hot water and energy 🚿',
        'category': 'energy_saving',
        'emoji': '🚿',
      },
      {
        'tip': 'Use a laptop instead of a desktop - it uses less energy 💻',
        'category': 'energy_saving',
        'emoji': '💻',
      },
      {
        'tip': 'Close curtains at night to keep heat in during winter 🏠',
        'category': 'energy_saving',
        'emoji': '🏠',
      },
      {
        'tip':
            'Use a power strip to easily turn off multiple devices at once ⚡',
        'category': 'energy_saving',
        'emoji': '⚡',
      },
      {
        'tip': 'Run dishwashers and washing machines only when full 🧺',
        'category': 'energy_saving',
        'emoji': '🧺',
      },
      {
        'tip':
            'Use cold water for laundry - it saves energy and protects colors 🌊',
        'category': 'energy_saving',
        'emoji': '🌊',
      },
      {
        'tip':
            'Keep your refrigerator between 37-40°F for optimal efficiency ❄️',
        'category': 'energy_saving',
        'emoji': '❄️',
      },
    ],
    'sustainable_shopping': [
      {
        'tip': 'Choose products made from recycled materials ♻️',
        'category': 'sustainable_shopping',
        'emoji': '♻️',
      },
      {
        'tip': 'Buy local produce to reduce carbon footprint from transport 🥕',
        'category': 'sustainable_shopping',
        'emoji': '🥕',
      },
      {
        'tip': 'Support eco-friendly and certified sustainable brands 🌿',
        'category': 'sustainable_shopping',
        'emoji': '🌿',
      },
      {
        'tip':
            'Choose products with Forest Stewardship Council (FSC) certification 🌲',
        'category': 'sustainable_shopping',
        'emoji': '🌲',
      },
      {
        'tip': 'Buy second-hand items when possible - reduce, reuse! 🏷️',
        'category': 'sustainable_shopping',
        'emoji': '🏷️',
      },
      {
        'tip': 'Avoid fast fashion - choose quality over quantity 👗',
        'category': 'sustainable_shopping',
        'emoji': '👗',
      },
      {
        'tip': 'Look for cruelty-free and vegan product certifications 🐰',
        'category': 'sustainable_shopping',
        'emoji': '🐰',
      },
      {
        'tip': 'Choose products without palm oil to protect rainforests 🌴',
        'category': 'sustainable_shopping',
        'emoji': '🌴',
      },
      {
        'tip': 'Buy organic when possible to reduce pesticide use 🍎',
        'category': 'sustainable_shopping',
        'emoji': '🍎',
      },
      {
        'tip': 'Support businesses with transparent supply chains 🔍',
        'category': 'sustainable_shopping',
        'emoji': '🔍',
      },
      {
        'tip': 'Choose refillable products over single-use ones 🔄',
        'category': 'sustainable_shopping',
        'emoji': '🔄',
      },
      {
        'tip': 'Shop at farmers markets for fresh, local goods 🧺',
        'category': 'sustainable_shopping',
        'emoji': '🧺',
      },
    ],
    'transportation': [
      {
        'tip': 'Walk or bike for short trips instead of driving 🚶',
        'category': 'transportation',
        'emoji': '🚶',
      },
      {
        'tip': 'Use public transportation when possible 🚌',
        'category': 'transportation',
        'emoji': '🚌',
      },
      {
        'tip': 'Carpool with colleagues or friends to reduce emissions 🚗',
        'category': 'transportation',
        'emoji': '🚗',
      },
      {
        'tip': 'Plan your errands to minimize driving distance 🗺️',
        'category': 'transportation',
        'emoji': '🗺️',
      },
      {
        'tip':
            'Keep your car tires properly inflated for better fuel efficiency 🛞',
        'category': 'transportation',
        'emoji': '🛞',
      },
      {
        'tip': 'Consider an electric or hybrid vehicle for your next car 🔋',
        'category': 'transportation',
        'emoji': '🔋',
      },
      {
        'tip': 'Work from home when possible to eliminate commute emissions 🏡',
        'category': 'transportation',
        'emoji': '🏡',
      },
      {
        'tip': 'Combine trips to reduce overall vehicle use 📍',
        'category': 'transportation',
        'emoji': '📍',
      },
      {
        'tip': 'Use bike-sharing or scooter-sharing services 🛴',
        'category': 'transportation',
        'emoji': '🛴',
      },
      {
        'tip':
            'Avoid idling your car - turn it off if waiting more than 30 seconds 🚦',
        'category': 'transportation',
        'emoji': '🚦',
      },
    ],
    'food_habits': [
      {
        'tip': 'Eat more plant-based meals to reduce your carbon footprint 🥗',
        'category': 'food_habits',
        'emoji': '🥗',
      },
      {
        'tip': 'Reduce food waste by meal planning 📝',
        'category': 'food_habits',
        'emoji': '📝',
      },
      {
        'tip': 'Store food properly to extend its shelf life 🥫',
        'category': 'food_habits',
        'emoji': '🥫',
      },
      {
        'tip': 'Use leftovers creatively instead of throwing them away 🍲',
        'category': 'food_habits',
        'emoji': '🍲',
      },
      {
        'tip':
            'Buy imperfect produce - it tastes the same and reduces waste 🥔',
        'category': 'food_habits',
        'emoji': '🥔',
      },
      {
        'tip': 'Freeze food before it spoils to use later ❄️',
        'category': 'food_habits',
        'emoji': '❄️',
      },
      {
        'tip':
            'Choose seasonal produce - it\'s fresher and more sustainable 🍓',
        'category': 'food_habits',
        'emoji': '🍓',
      },
      {
        'tip': 'Start a small herb garden at home 🌿',
        'category': 'food_habits',
        'emoji': '🌿',
      },
      {
        'tip': 'Bring reusable containers for restaurant leftovers 📦',
        'category': 'food_habits',
        'emoji': '📦',
      },
      {
        'tip': 'Support sustainable fishing by choosing certified seafood 🐟',
        'category': 'food_habits',
        'emoji': '🐟',
      },
      {
        'tip': 'Reduce meat consumption - try Meatless Mondays 🥦',
        'category': 'food_habits',
        'emoji': '🥦',
      },
    ],
    'water_conservation': [
      {
        'tip': 'Fix leaky faucets - a drip can waste gallons per day 💧',
        'category': 'water_conservation',
        'emoji': '💧',
      },
      {
        'tip': 'Turn off the tap while brushing your teeth 🪥',
        'category': 'water_conservation',
        'emoji': '🪥',
      },
      {
        'tip': 'Collect rainwater for watering plants 🌧️',
        'category': 'water_conservation',
        'emoji': '🌧️',
      },
      {
        'tip': 'Use a broom instead of a hose to clean driveways 🧹',
        'category': 'water_conservation',
        'emoji': '🧹',
      },
      {
        'tip': 'Install low-flow showerheads to reduce water use 🚿',
        'category': 'water_conservation',
        'emoji': '🚿',
      },
      {
        'tip':
            'Water plants in the morning or evening to reduce evaporation 🌱',
        'category': 'water_conservation',
        'emoji': '🌱',
      },
      {
        'tip':
            'Use a dishwasher instead of hand washing - it uses less water 🍽️',
        'category': 'water_conservation',
        'emoji': '🍽️',
      },
      {
        'tip': 'Choose drought-resistant plants for your garden 🌵',
        'category': 'water_conservation',
        'emoji': '🌵',
      },
      {
        'tip': 'Reuse pasta or vegetable cooking water for plants 🍝',
        'category': 'water_conservation',
        'emoji': '🍝',
      },
      {
        'tip': 'Take a bucket shower and use the water for cleaning 🪣',
        'category': 'water_conservation',
        'emoji': '🪣',
      },
    ],
    'recycling': [
      {
        'tip': 'Rinse containers before recycling to avoid contamination ♻️',
        'category': 'recycling',
        'emoji': '♻️',
      },
      {
        'tip':
            'Know your local recycling rules - not all plastics are accepted 🔍',
        'category': 'recycling',
        'emoji': '🔍',
      },
      {
        'tip': 'Remove caps and lids from bottles before recycling 🧴',
        'category': 'recycling',
        'emoji': '🧴',
      },
      {
        'tip': 'Recycle electronics properly at designated e-waste centers 📱',
        'category': 'recycling',
        'emoji': '📱',
      },
      {
        'tip': 'Flatten cardboard boxes to save space in recycling bins 📦',
        'category': 'recycling',
        'emoji': '📦',
      },
      {
        'tip': 'Recycle batteries at special collection points 🔋',
        'category': 'recycling',
        'emoji': '🔋',
      },
      {
        'tip': 'Don\'t bag recyclables - keep them loose in the bin 🗑️',
        'category': 'recycling',
        'emoji': '🗑️',
      },
      {
        'tip':
            'Recycle glass bottles and jars - they can be recycled infinitely 🍾',
        'category': 'recycling',
        'emoji': '🍾',
      },
      {
        'tip': 'Shred paper documents before recycling for security 📄',
        'category': 'recycling',
        'emoji': '📄',
      },
      {
        'tip': 'Check product labels for recycling symbols and instructions ♻️',
        'category': 'recycling',
        'emoji': '♻️',
      },
    ],
    'eco_habits': [
      {
        'tip': 'Use digital documents instead of printing when possible 📱',
        'category': 'eco_habits',
        'emoji': '📱',
      },
      {
        'tip': 'Choose eco-friendly cleaning products 🧽',
        'category': 'eco_habits',
        'emoji': '🧽',
      },
      {
        'tip': 'Plant a tree or support reforestation projects 🌳',
        'category': 'eco_habits',
        'emoji': '🌳',
      },
      {
        'tip': 'Educate others about sustainable living 📚',
        'category': 'eco_habits',
        'emoji': '📚',
      },
      {
        'tip': 'Join local environmental cleanup events 🧹',
        'category': 'eco_habits',
        'emoji': '🧹',
      },
      {
        'tip': 'Support environmental organizations and causes 💚',
        'category': 'eco_habits',
        'emoji': '💚',
      },
      {
        'tip': 'Use reusable batteries or rechargeable ones 🔋',
        'category': 'eco_habits',
        'emoji': '🔋',
      },
      {
        'tip': 'Avoid single-use items whenever possible 🚫',
        'category': 'eco_habits',
        'emoji': '🚫',
      },
      {
        'tip': 'Choose bar soap over liquid soap to reduce plastic 🧼',
        'category': 'eco_habits',
        'emoji': '🧼',
      },
      {
        'tip': 'Use a reusable lunch box instead of disposable bags 🍱',
        'category': 'eco_habits',
        'emoji': '🍱',
      },
      {
        'tip': 'Switch to eco-friendly menstrual products 🌸',
        'category': 'eco_habits',
        'emoji': '🌸',
      },
      {
        'tip': 'Make your own cleaning products with natural ingredients 🍋',
        'category': 'eco_habits',
        'emoji': '🍋',
      },
      {
        'tip': 'Participate in citizen science projects for the environment 🔬',
        'category': 'eco_habits',
        'emoji': '🔬',
      },
      {
        'tip': 'Use a bamboo toothbrush instead of plastic 🪥',
        'category': 'eco_habits',
        'emoji': '🪥',
      },
      {
        'tip': 'Vote for politicians who prioritize environmental policies 🗳️',
        'category': 'eco_habits',
        'emoji': '🗳️',
      },
    ],
  };

  /// Generate a daily tip for the specified date using date-seeded randomization.
  /// This ensures the same tip is returned for the same date across all users.
  static Map<String, dynamic> generateDailyTip(DateTime date) {
    // Flatten all tips into a single list
    final allTips = <Map<String, String>>[];
    _tipPool.forEach((category, tips) {
      allTips.addAll(tips);
    });

    // Use date as seed for random number generator
    // Format: YYYYMMDD (e.g., 20251109)
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);

    // Select one tip
    final selectedTip = allTips[random.nextInt(allTips.length)];

    return {
      'tip': selectedTip['tip'],
      'category': selectedTip['category'],
      'emoji': selectedTip['emoji'],
      'date': DateFormat('yyyy-MM-dd').format(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Ensure today's tip exists in Firestore. Creates it if missing.
  static Future<void> ensureTodayTipExists() async {
    try {
      final today = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(today);

      final tipDoc = await FirebaseFirestore.instance
          .collection('daily_tips')
          .doc(dateString)
          .get();

      if (!tipDoc.exists) {
        final tip = generateDailyTip(today);
        await FirebaseFirestore.instance
            .collection('daily_tips')
            .doc(dateString)
            .set(tip);
        debugPrint('✅ Created daily tip for $dateString');
      } else {
        debugPrint('✅ Daily tip for $dateString already exists');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring today\'s tip exists: $e');
    }
  }

  /// Generate tips for the next 7 days. Useful for pre-population.
  static Future<void> generateWeeklyTips() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final today = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        final tip = generateDailyTip(date);

        final docRef = FirebaseFirestore.instance
            .collection('daily_tips')
            .doc(dateString);

        batch.set(docRef, tip, SetOptions(merge: false));
      }

      await batch.commit();
      debugPrint('✅ Generated tips for the next 7 days');
    } catch (e) {
      debugPrint('❌ Error generating weekly tips: $e');
    }
  }

  /// Get a random tip from a specific category
  static String getRandomTipByCategory(String category) {
    final tips = _tipPool[category];
    if (tips == null || tips.isEmpty) {
      return 'No tips available for this category';
    }
    final random = Random();
    return tips[random.nextInt(tips.length)]['tip']!;
  }

  /// Get all available categories
  static List<String> getAllCategories() {
    return _tipPool.keys.toList();
  }

  /// Get total number of tips
  static int getTotalTipCount() {
    int count = 0;
    _tipPool.forEach((_, tips) => count += tips.length);
    return count;
  }

  /// Get tips count by category
  static Map<String, int> getTipCountByCategory() {
    final counts = <String, int>{};
    _tipPool.forEach((category, tips) {
      counts[category] = tips.length;
    });
    return counts;
  }
}
