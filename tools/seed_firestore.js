/**
 * Seed Firestore with a sample `products` document for local/dev testing.
 *
 * Usage:
 *   1) Create a service account JSON in Google Cloud with Firestore access.
 *   2) Set environment variable: GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
 *   3) Set FIREBASE_PROJECT_ID to your project id (optional if present in key)
 *   4) Run: node tools/seed_firestore.js
 *
 * This script uses the Firebase Admin SDK (Node.js). It performs a single
 * upsert of a sample product document under collection `products`.
 */

const admin = require('firebase-admin');
const fs = require('fs');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Please set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path.');
  process.exit(2);
}

try {
  admin.initializeApp();
} catch (e) {
  // already initialized in some runtimes
}

const db = admin.firestore();

async function seed() {
  try {
    const sample = {
      name: 'Mineral Water (Sample)',
      code: '0000000000000',
      categories: ['Beverages', 'Water'],
      eco_score: 'B',
      co2_footprint: 0.02,
      packaging: 'plastic bottle',
      description: 'Sample mineral water entry for local testing',
      createdAt: new Date().toISOString(),
    };

    const ref = db.collection('products').doc('sample_mineral_water');
    await ref.set(sample, { merge: true });
    console.log('Seeded sample product: products/sample_mineral_water');
  } catch (err) {
    console.error('Seeding failed:', err);
    process.exit(1);
  }
}

seed();
