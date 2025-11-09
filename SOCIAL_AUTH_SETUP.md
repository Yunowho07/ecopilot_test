# Social Authentication Setup Guide

## ✅ Already Implemented

Your app already has **complete Facebook and Apple authentication integration**! Here's what's included:

### **Code Implementation:**
- ✅ Facebook Sign-In in `login.dart` and `signup.dart`
- ✅ Apple Sign-In in `login.dart` and `signup.dart`
- ✅ Google Sign-In in `login.dart` and `signup.dart`
- ✅ Backend service methods in `firebase_service.dart`
- ✅ User profile creation after social sign-in
- ✅ Proper error handling and loading states
- ✅ Web and mobile platform support

### **Dependencies:**
- ✅ `flutter_facebook_auth: ^7.1.2`
- ✅ `sign_in_with_apple: ^6.0.0`
- ✅ `google_sign_in: ^6.2.2`

---

## 📋 Configuration Required

To enable these features, you need to configure the authentication providers:

### **1. Facebook Authentication Setup**

#### A. Create Facebook App
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **"My Apps"** → **"Create App"**
3. Select **"Consumer"** as app type
4. Enter your app details:
   - **App Name:** EcoPilot
   - **Contact Email:** Your email
5. Click **"Create App"**

#### B. Get Facebook App ID and Secret
1. From the app dashboard, copy:
   - **App ID**
   - **App Secret** (Settings → Basic)

#### C. Configure Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project **"ecopilot_test"**
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Facebook** provider
5. Enter your **App ID** and **App Secret**
6. Copy the **OAuth redirect URI** shown

#### D. Configure Facebook App
1. Return to Facebook Developers dashboard
2. Go to **Facebook Login** → **Settings**
3. Add the **OAuth redirect URI** from Firebase to:
   - **Valid OAuth Redirect URIs**
4. Save changes

#### E. Android Configuration
Add to `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
</resources>
```

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data 
    android:name="com.facebook.sdk.ApplicationId" 
    android:value="@string/facebook_app_id"/>
    
<meta-data 
    android:name="com.facebook.sdk.ClientToken" 
    android:value="@string/facebook_client_token"/>

<activity 
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />
    
<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

#### F. iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fbYOUR_FACEBOOK_APP_ID</string>
    </array>
  </dict>
</array>
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>EcoPilot</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fb-messenger-share-api</string>
</array>
```

---

### **2. Apple Sign-In Setup**

#### A. Apple Developer Account
1. Ensure you have an **Apple Developer Account** ($99/year)
2. Go to [Apple Developer Portal](https://developer.apple.com/)

#### B. Configure App ID
1. Navigate to **Certificates, Identifiers & Profiles**
2. Select **Identifiers** → Your App ID
3. Enable **Sign in with Apple** capability
4. Save changes

#### C. Configure Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Apple** provider
5. Enter your **Service ID** (optional)

#### D. iOS Configuration
Add to `ios/Runner/Runner.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

Enable in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Sign in with Apple**

#### E. Android/Web Configuration
Apple Sign-In on Android/Web requires additional Service ID configuration:

1. In Apple Developer Portal, create a **Service ID**
2. Enable **Sign in with Apple**
3. Configure domains and return URLs
4. Use the Service ID in your app configuration

---

### **3. Google Sign-In Setup**

#### A. Firebase Console
1. Google Sign-In is **enabled by default** in Firebase
2. Verify it's enabled in **Authentication** → **Sign-in method**

#### B. Android Configuration
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. The SHA-1 fingerprint should be registered in Firebase

To get SHA-1:
```bash
cd android
./gradlew signingReport
```

Copy the SHA-1 and add to Firebase Console:
- Project Settings → Your Android App → Add fingerprint

#### C. iOS Configuration
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/` in Xcode

Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### D. Web Configuration
Add to `web/index.html`:
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

---

## 🧪 Testing

### Test Each Provider:

1. **Facebook:**
   ```
   - Tap "Continue with Facebook"
   - Log in with Facebook credentials
   - Verify user is created in Firebase
   ```

2. **Apple:**
   ```
   - Tap "Continue with Apple"
   - Use Face ID/Touch ID or Apple ID
   - Verify user is created in Firebase
   ```

3. **Google:**
   ```
   - Tap "Continue with Google"
   - Select Google account
   - Verify user is created in Firebase
   ```

### Verify in Firebase:
1. Go to Firebase Console
2. Navigate to **Authentication** → **Users**
3. Check that users appear with correct provider (facebook.com, apple.com, google.com)

---

## 🔐 Security Best Practices

1. **Never commit sensitive keys** to version control
2. Use **environment variables** for API keys
3. Enable **App Check** in Firebase for additional security
4. Implement **rate limiting** on authentication endpoints
5. Use **Firebase Security Rules** to protect user data

---

## 📝 Code Features

### Already Implemented Features:

✅ **Profile Creation:** Automatic Firestore profile creation after social sign-in
✅ **Error Handling:** User-friendly error messages with proper exception handling
✅ **Loading States:** Shows loading indicators during authentication
✅ **Platform Detection:** Different implementations for iOS, Android, and Web
✅ **Nonce Generation:** Secure nonce generation for Apple Sign-In
✅ **User Data Storage:** User info stored in Firestore with:
   - Display name
   - Email
   - Photo URL
   - Eco points (initialized to 0)
   - Creation timestamp

### User Flow:
1. User taps social login button
2. Loading indicator shows
3. Provider-specific authentication flow
4. On success:
   - User authenticated with Firebase
   - Profile created/updated in Firestore
   - Navigate to Home Screen
5. On failure:
   - Show error message
   - User stays on login screen

---

## 🎨 UI Features

The login and signup screens have:
- ✅ Beautiful gradient headers
- ✅ Modern card-based social login buttons
- ✅ Platform-specific Apple Sign-In button (iOS/macOS)
- ✅ Consistent branding with EcoPilot theme
- ✅ Responsive design for all screen sizes

---

## 🚀 Next Steps

1. Configure Facebook Developer App
2. Configure Apple Developer Account (if targeting iOS)
3. Verify Google Sign-In configuration
4. Add your API keys to the appropriate platform files
5. Test each authentication method
6. Deploy to production

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console logs
2. Verify all configuration files
3. Ensure dependencies are up to date
4. Check platform-specific documentation:
   - [Facebook Login for Flutter](https://pub.dev/packages/flutter_facebook_auth)
   - [Sign in with Apple for Flutter](https://pub.dev/packages/sign_in_with_apple)
   - [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)

---

## ✨ Summary

Your EcoPilot app has **complete social authentication** already coded and ready to use! You just need to:

1. **Configure the providers** (Facebook App, Apple Developer Account)
2. **Add configuration files** to Android/iOS
3. **Test the flows**
4. **Deploy!**

The code is production-ready with proper error handling, user experience, and data persistence. 🎉
