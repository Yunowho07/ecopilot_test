@echo off
echo ========================================
echo   Gemini Alternatives System Setup
echo ========================================
echo.

echo Step 1: Deploying Firestore Security Rules...
firebase deploy --only firestore:rules

echo.
echo Step 2: Creating Firestore indexes (if needed)...
firebase deploy --only firestore:indexes

echo.
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo Your Gemini-powered alternatives system is ready!
echo.
echo Next steps:
echo   1. Restart your Flutter app
echo   2. Scan a product
echo   3. View alternatives (will cache to Firestore)
echo   4. Check Firestore Console for 'alternative_products' collection
echo.
pause
