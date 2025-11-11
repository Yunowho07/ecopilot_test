#!/bin/bash

# Dynamic Notifications Setup Script
# Run this script to quickly set up the dynamic notification system

echo "🔔 EcoPilot Dynamic Notifications Setup"
echo "========================================"
echo ""

# Step 1: Install Flutter dependencies
echo "📦 Step 1: Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
  echo "✅ Flutter dependencies installed successfully"
else
  echo "❌ Failed to install Flutter dependencies"
  exit 1
fi

echo ""

# Step 2: Deploy Firebase Cloud Functions
echo "🚀 Step 2: Deploying Firebase Cloud Functions..."
cd functions

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "📦 Installing Cloud Functions dependencies..."
  npm install
fi

echo "Deploying dynamic notification functions..."
firebase deploy --only functions:onStreakMilestone,functions:onPointsMilestone,functions:onProductScanned,functions:onRankUpdate,functions:sendDailyChallengeReminder,functions:sendDailyEcoTip,functions:sendBroadcastNotification

if [ $? -eq 0 ]; then
  echo "✅ Cloud Functions deployed successfully"
else
  echo "❌ Failed to deploy Cloud Functions"
  echo "ℹ️  Make sure you're logged in: firebase login"
  exit 1
fi

cd ..

echo ""

# Step 3: Update Firestore security rules
echo "🔐 Step 3: Updating Firestore security rules..."
echo "Please add the following to your firestore.rules:"
echo ""
echo "match /notifications/{notificationId} {"
echo "  allow read: if request.auth != null && "
echo "    resource.data.userId == request.auth.uid;"
echo "  allow write: if false;"
echo "}"
echo ""
echo "Then run: firebase deploy --only firestore:rules"
echo ""

# Step 4: Configuration checklist
echo "✅ Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Configure FCM for Android (AndroidManifest.xml)"
echo "2. Configure FCM for iOS (Xcode capabilities)"
echo "3. Update Firestore security rules (see above)"
echo "4. Test notifications with: flutter run"
echo ""
echo "📖 Full guide: See DYNAMIC_NOTIFICATIONS_GUIDE.md"
echo ""
