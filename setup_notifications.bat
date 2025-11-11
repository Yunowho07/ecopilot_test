@echo off
REM Dynamic Notifications Setup Script for Windows
REM Run this script to quickly set up the dynamic notification system

echo ================================================
echo    EcoPilot Dynamic Notifications Setup
echo ================================================
echo.

REM Step 1: Install Flutter dependencies
echo Step 1: Installing Flutter dependencies...
call flutter pub get

if %errorlevel% equ 0 (
  echo [SUCCESS] Flutter dependencies installed successfully
) else (
  echo [ERROR] Failed to install Flutter dependencies
  exit /b 1
)

echo.

REM Step 2: Deploy Firebase Cloud Functions
echo Step 2: Deploying Firebase Cloud Functions...
cd functions

REM Check if node_modules exists
if not exist "node_modules" (
  echo Installing Cloud Functions dependencies...
  call npm install
)

echo Deploying dynamic notification functions...
call firebase deploy --only functions:onStreakMilestone,functions:onPointsMilestone,functions:onProductScanned,functions:onRankUpdate,functions:sendDailyChallengeReminder,functions:sendDailyEcoTip,functions:sendBroadcastNotification

if %errorlevel% equ 0 (
  echo [SUCCESS] Cloud Functions deployed successfully
) else (
  echo [ERROR] Failed to deploy Cloud Functions
  echo Make sure you're logged in: firebase login
  exit /b 1
)

cd ..

echo.

REM Step 3: Update Firestore security rules
echo Step 3: Updating Firestore security rules...
echo Please add the following to your firestore.rules:
echo.
echo match /notifications/{notificationId} {
echo   allow read: if request.auth != null ^&^& 
echo     resource.data.userId == request.auth.uid;
echo   allow write: if false;
echo }
echo.
echo Then run: firebase deploy --only firestore:rules
echo.

REM Step 4: Configuration checklist
echo ================================================
echo                Setup Complete!
echo ================================================
echo.
echo Next Steps:
echo 1. Configure FCM for Android (AndroidManifest.xml)
echo 2. Configure FCM for iOS (Xcode capabilities)
echo 3. Update Firestore security rules (see above)
echo 4. Test notifications with: flutter run
echo.
echo Full guide: See DYNAMIC_NOTIFICATIONS_GUIDE.md
echo.
pause
