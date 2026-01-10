# Google Sign-In & Password Reset Fix Guide

## Problem 1: Google Sign-In Error
Getting error: `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)`

**Error Code 10** = `DEVELOPER_ERROR` - This means your app's SHA-1 fingerprint is not configured in Firebase Console.

---

## Solution: Add SHA-1 Fingerprint to Firebase

### Step 1: Get Your SHA-1 Fingerprint

Open PowerShell in your project directory and run:

```powershell
# For Debug Build (Testing)
cd android
./gradlew signingReport
```

Or use this command directly:

```powershell
keytool -list -v -keystore "C:\Users\%USERNAME%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

You'll see output like:
```
Certificate fingerprints:
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
SHA256: ...
```

**Your SHA-1:** `19:73:E8:83:F6:03:2C:16:A1:35:2D:4D:DC:8D:73:D3:59:DA:E6:90`

---

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ecopilot_test**
3. Click the **Settings gear icon** ⚙️ → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app (com.example.ecopilot_test or similar)
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

---

### Step 3: Download Updated google-services.json

1. Still in Firebase Console, on the same page
2. Click **Download google-services.json**
3. Replace the old file in your project:
   - Location: `android/app/google-services.json`
4. **Important**: Make sure to replace the existing file!

---

### Step 4: Clean and Rebuild

```powershell
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Rebuild the app
flutter run
```

---

## Problem 2: Password Reset Email Not Received

### Possible Causes:

1. **Email is not registered in Firebase Auth**
   - Firebase silently succeeds even for non-existent emails (security feature)
   - Check if the email is actually registered

2. **Email went to spam/junk folder**
   - Check your spam folder
   - Mark Firebase emails as "Not Spam"

3. **Firebase email templates not configured**
   - Email templates may need setup in Firebase Console

4. **Email provider blocking Firebase emails**
   - Some email providers filter automated emails

---

## Solution: Configure Firebase Email Settings

### Step 1: Verify Email is Registered

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ecopilot_test**
3. Navigate to **Authentication** → **Users** tab
4. Search for the email address
5. If not found, the user needs to sign up first

### Step 2: Configure Email Templates

1. In Firebase Console → **Authentication** → **Templates**
2. Click on **Password reset** template
3. Customize the email template:
   - **From name**: EcoPilot
   - **Reply-to email**: your-support@email.com
   - **Subject**: Reset your EcoPilot password
   - **Body**: Customize the message
4. Click **Save**

### Step 3: Add Authorized Domains

1. In Firebase Console → **Authentication** → **Settings** tab
2. Scroll to **Authorized domains**
3. Make sure your domain is listed
4. Add any custom domains if needed

### Step 4: Test with Known Email

1. Create a test account with a Gmail address
2. Try password reset with that account
3. Check if email arrives
4. If it works, the issue is with the specific email address

---

## Troubleshooting Steps

### If Still Not Receiving Emails:

1. **Wait 5-10 minutes**
   - Firebase emails can be delayed
   - Check inbox periodically

2. **Check ALL email folders**
   - Inbox
   - Spam/Junk
   - Promotions (Gmail)
   - Updates (Gmail)
   - Social (Gmail)

3. **Verify Email Address**
   - Make sure there are no typos
   - Try copying/pasting the email

4. **Check Email Provider Settings**
   - Some providers block automated emails
   - Check email filters/rules
   - Whitelist Firebase domains:
     - `firebase.google.com`
     - `firebaseapp.com`
     - `noreply@*.firebaseapp.com`

5. **Test with Different Email**
   - Try Gmail (usually reliable)
   - Try a different email provider

6. **Check Firebase Quotas**
   - Go to Firebase Console → **Authentication**
   - Check if you've hit email sending limits
   - Free tier: 100 emails/day

---

## Quick Fix Command Summary

Run these commands in order:

```powershell
# 1. Get SHA-1
cd android
./gradlew signingReport

# 2. After adding to Firebase and downloading google-services.json:

# 3. Clean and rebuild
cd ..
flutter clean
flutter pub get
flutter run
```

---

## Verification

### Google Sign-In Working:
1. Tap "Continue with Google"
2. See the Google account picker
3. Select your Google account
4. Successfully sign in to the app ✅

### Password Reset Working:
1. Tap "Forgot Password"
2. Enter registered email
3. Receive reset email within 5 minutes
4. Click link in email
5. Successfully reset password ✅

---

## Common Issues

### "Keystore file does not exist"
- The debug keystore is automatically created the first time you run a Flutter app
- Try running `flutter run` once, then check again

### "SHA-1 still not working"
- Make sure you added the SHA-1 to the **correct app** in Firebase
- Wait 5-10 minutes after adding SHA-1 (changes need to propagate)
- Download the **new** google-services.json file
- Delete the old google-services.json before adding the new one

### Multiple Build Variants
If you have multiple build variants (debug, release, production), add SHA-1 for each:
- Debug keystore SHA-1 (for testing)
- Release keystore SHA-1 (for production)
- Any other custom keystores

### Email Not in Spam
If email is not in spam and still not received:
- Verify the email is actually registered in Firebase Auth
- Check Firebase Console → Authentication → Users
- Create a new account and test immediately
- Try a different email provider (Gmail is most reliable)

---

**Need More Help?**

Check the Firebase Console for any warnings or errors in the Authentication section.
