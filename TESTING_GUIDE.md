# 🧪 Better Alternative Screen - Testing Guide

## 🎯 Quick Start

Run the app and follow these test scenarios to verify everything works as shown in the flow diagram.

---

## ✅ Test Scenario 1: Complete Happy Path (Gemini AI Working)

### Expected Flow:
```
Scan Product → View Results → Tap "Better Alternative" → 
See Gemini-generated alternatives → Compare → Buy Now
```

### Steps:
1. **Launch App**
   ```bash
   flutter run
   ```

2. **Scan Product A** (e.g., Mineral Water Bottle)
   - Use camera scan or barcode
   - Wait for Gemini analysis
   - Result Screen appears

3. **Check Result Screen**
   - ✅ Product name displayed
   - ✅ Eco score badge (colored A+ to E)
   - ✅ "Better Alternative" button visible

4. **Tap "Better Alternative" Button**
   - Alternative Screen opens
   - Loading indicator appears
   - Console shows:
     ```
     🔄 Starting alternative generation for: Mineral Water Bottle
     📍 Step 1: Trying Gemini AI...
     🤖 Trying Gemini AI for alternatives...
     ```

5. **Verify Alternatives Load**
   - Console shows:
     ```
     ✅ Gemini response received (1847 chars)
     🔍 Parsing JSON...
     ✅ JSON parsed successfully, found 5 items
     ✓ Adding alternative: EcoBottle Stainless Steel (A+)
     ✓ Adding alternative: Glass Water Bottle (A)
     ✅ Successfully generated 5 alternatives from Gemini
     ```
   - Screen shows: **"Source: Gemini AI ✨"**
   - At least 3 alternatives displayed
   - Each shows:
     - Product image
     - Product name
     - Eco score badge (green/yellow)
     - Material type
     - Price (RM)
     - Rating (⭐)
     - Carbon savings
     - 3 action buttons

6. **Test Different Product** (e.g., Shampoo Bottle)
   - Scan different product
   - Tap "Better Alternative"
   - Verify alternatives are **DIFFERENT** from Product A
   - This confirms Gemini is generating unique alternatives

7. **Test Compare Feature**
   - Tap "Compare" button on any alternative
   - Modal appears showing:
     - Side-by-side comparison
     - Current product vs Alternative
     - Eco scores compared
     - Materials compared
     - Carbon impact difference
     - Better values marked with ✅

8. **Test Details View**
   - Tap "Details" button
   - Modal shows:
     - Full product image
     - Complete description
     - Material details
     - Carbon savings
     - Buy link section

9. **Test Buy Now**
   - Tap "Buy Now" button
   - External browser opens OR
   - Snackbar: "Link copied to clipboard"
   - Verify it's a real Shopee/Lazada link

---

## ⚠️ Test Scenario 2: Fallback to Sample Data (No Internet/API Failure)

### Expected Flow:
```
Scan Product → Tap "Better Alternative" → 
Gemini fails → Firestore fails → Cloudinary fails → 
Sample data displayed
```

### Steps:

1. **Simulate Failure** (Choose one method):
   - **Method A:** Disconnect internet/Wi-Fi
   - **Method B:** Set invalid API key in `.env`:
     ```
     GOOGLE_API_KEY=invalid_key_test
     ```
   - **Method C:** Remove API key entirely

2. **Scan Any Product**
   - Product analysis may fail (that's okay)
   - Or use a previously scanned product from Recent Activity

3. **Tap "Better Alternative"**
   - Console shows fallback sequence:
     ```
     🔄 Starting alternative generation
     📍 Step 1: Trying Gemini AI...
     ❌ Gemini API error: __GEMINI_ERROR__
     📍 Step 2: Trying Firestore database...
     ❌ Firestore fetch failed
     📍 Step 3: Trying Cloudinary JSON...
     ❌ Cloudinary fetch failed
     ⚠️ All sources failed, using sample fallback data
     ```

4. **Verify Sample Alternatives Appear**
   - Screen shows: **"Source: Sample Data 📊"**
   - Exactly 5 alternatives displayed:
     1. EcoBottle Stainless Steel (A+) - RM 45.00
     2. Glass Water Bottle with Bamboo Cap (A) - RM 38.00
     3. Aluminum Refillable Bottle (B) - RM 32.00
     4. Bamboo Fiber Water Bottle (A) - RM 35.00
     5. Collapsible Silicone Bottle (B) - RM 28.00

5. **Verify All Features Still Work**
   - Compare button works
   - Details modal works
   - Buy links work (opens Shopee search)

---

## 🏠 Test Scenario 3: Recent Activity Integration

### Expected Flow:
```
Home Screen → Recent Activity → Tap past scan → 
Product detail modal → "View Better Alternatives" → 
Alternative Screen opens
```

### Steps:

1. **Ensure You Have Recent Scans**
   - If not, scan 2-3 products first

2. **Go to Home Screen**
   - Tap Home icon in bottom navigation

3. **Find Recent Activity Section**
   - Should show recently scanned products
   - Each with small thumbnail and product name

4. **Tap on Any Recent Product**
   - Product detail modal opens
   - Shows full product information:
     - Product image
     - Name, category, eco score
     - Ingredients
     - Carbon footprint
     - Packaging type
     - Environmental impact

5. **Verify "View Better Alternatives" Button**
   - Button should be visible at bottom of modal
   - Green button with 🌿 icon

6. **Tap "View Better Alternatives"**
   - Alternative Screen opens
   - Same product data passed
   - Alternatives generated/loaded
   - Works exactly like from Result Screen

---

## 🔍 Test Scenario 4: Filter System

### Expected Flow:
```
Alternative Screen → Tap "Filters" → 
Set price/brand/rating filters → 
See filtered results
```

### Steps:

1. **Open Alternative Screen** (any method)
   - Ensure alternatives are loaded

2. **Tap "Filters" Button**
   - Located in top-right of green header
   - Filter panel expands below header

3. **Test Price Filter**
   - Adjust "Maximum Price (RM)" slider
   - Move to RM 40
   - Verify alternatives update
   - Only products ≤ RM 40 shown

4. **Test Brand Filter** (if brands available)
   - Open "Brand" dropdown
   - Select a specific brand
   - Verify only that brand's products shown

5. **Test Rating Filter**
   - Tap rating chips (3.0, 3.5, 4.0, 4.5)
   - Verify only products with ≥ selected rating shown

6. **Test Reset Filters**
   - Tap "Reset" button
   - All filters cleared
   - All alternatives shown again

7. **Close Filters**
   - Tap "Filters" button again
   - Panel collapses

---

## ❤️ Test Scenario 5: Wishlist Feature

### Expected Flow:
```
Alternative Screen → Tap ❤️ icon → 
Saved to Firebase → Icon becomes 💚 → 
Persistent across app
```

### Steps:

1. **Ensure User is Logged In**
   - Firebase Authentication required
   - If not logged in, you'll see error message

2. **Open Alternative Screen**
   - Alternatives loaded

3. **Tap ❤️ Icon on Any Alternative**
   - Icon changes: ❤️ → 💚 (filled)
   - Snackbar appears: "Added to wishlist 💚"
   - Product saved to Firebase:
     ```
     /users/{userId}/wishlist/{productId}
     ```

4. **Verify Persistence**
   - Close Alternative Screen
   - Navigate away
   - Return to Alternative Screen
   - Same alternative shows 💚 (still in wishlist)

5. **Remove from Wishlist**
   - Tap 💚 icon
   - Icon changes back: 💚 → ❤️
   - Snackbar: "Removed from wishlist"

6. **Test Without Login** (if applicable)
   - Log out
   - Try to add to wishlist
   - Snackbar: "Please login to use wishlist"

---

## 📊 Test Scenario 6: Eco Score Color System

### Expected Flow:
```
Verify all eco score badges display correct colors
```

### Steps:

1. **Check Alternative Cards**
   - Look at eco score badges on each alternative
   - Verify colors match:
     - **A+** = Bright Green (#1DB954) 🟢
     - **A** = Green (#4CAF50) 🟢
     - **B** = Yellow-Green (#8BC34A) 🟡
     - **C** = Yellow (#FFEB3B) 🟡
     - **D** = Orange (#FF9800) 🟠
     - **E** = Red (#F44336) 🔴

2. **Check Comparison Modal**
   - Tap "Compare" on any alternative
   - Verify better eco score has ✅ checkmark
   - Verify better score is green colored

---

## 🐛 Debugging Tests

### Console Output Verification

#### **Successful Gemini Generation:**
```
🔄 Starting alternative generation for: Mineral Water Bottle
📍 Step 1: Trying Gemini AI...
🤖 Trying Gemini AI for alternatives...
   Product: Mineral Water Bottle
   Category: Beverages
   Eco Score: C
📤 Sending request to Gemini...
✅ Gemini response received (1847 chars)
📝 Response preview: [{"name":"EcoBottle...
🔍 Parsing JSON...
✅ JSON parsed successfully, found 5 items
   ✓ Adding alternative: EcoBottle Stainless Steel (A+)
   ✓ Adding alternative: Glass Water Bottle (A)
   ✓ Adding alternative: Aluminum Refillable Bottle (B)
   ✓ Adding alternative: Bamboo Fiber Bottle (A)
   ✓ Adding alternative: Collapsible Silicone Bottle (B)
✅ Successfully generated 5 alternatives from Gemini
✅ Success! Using Gemini AI alternatives
```

#### **Fallback Sequence:**
```
🔄 Starting alternative generation for: Shampoo Bottle
📍 Step 1: Trying Gemini AI...
❌ Gemini generation failed: [error details]
📍 Step 2: Trying Firestore database...
❌ Firestore fetch failed: [error details]
📍 Step 3: Trying Cloudinary JSON...
❌ Cloudinary fetch failed for [url]: [error]
⚠️ All sources failed, will use sample fallback data
```

---

## ✅ Success Checklist

After testing, verify:

- [ ] Gemini AI generates unique alternatives for different products
- [ ] Sample fallback works when Gemini fails
- [ ] "Source: Gemini AI ✨" appears when using AI
- [ ] "Source: Sample Data 📊" appears when using fallback
- [ ] At least 3-5 alternatives always shown
- [ ] All alternatives have better eco score than scanned product
- [ ] Compare modal works correctly
- [ ] Details modal shows all information
- [ ] Buy Now opens external links
- [ ] Wishlist saves to Firebase
- [ ] Filters work (price, brand, rating)
- [ ] Recent Activity integration works
- [ ] Console logs show emoji indicators
- [ ] Eco score colors are correct
- [ ] Bottom navigation works
- [ ] All buttons are responsive

---

## 🚨 Known Issues to Check

1. **All products showing same alternatives**
   - Check console for: ✅ Gemini response
   - Verify: "Source: Gemini AI ✨" appears
   - If "Source: Sample Data 📊" → Gemini is failing
   - Solution: Check API key, internet connection

2. **No alternatives appear**
   - Check console for errors
   - Verify `_sampleAlternatives` list exists
   - Should always show at least 5 sample alternatives

3. **Wishlist not saving**
   - Verify user is logged in
   - Check Firebase rules allow write access
   - Check console for Firebase errors

4. **Buy links not working**
   - Verify `buyLink` field has valid URL
   - Check if external browser permission granted

---

## 📞 Troubleshooting

### Issue: "No alternatives found" (empty screen)
**Solution:**
- Check if `_sampleAlternatives` list is defined
- Should have 5 hardcoded alternatives
- This was just added, restart app

### Issue: Gemini always fails
**Solution:**
- Check `.env` file has valid `GOOGLE_API_KEY`
- Test API key with: `flutter run --dart-define=GOOGLE_API_KEY=your_key`
- Check internet connection
- Verify Gemini API quota not exceeded

### Issue: Same alternatives for all products
**Solution:**
- Check console logs
- If you see "Source: Sample Data" → Gemini is failing
- If you see "Source: Gemini AI" but same results → API returning cached data
- Try different products with very different categories

---

## 🎉 Expected Result

**PERFECT TEST RUN:**
1. ✅ Scan Product A → Gemini generates 5 unique alternatives
2. ✅ Scan Product B → Gemini generates 5 DIFFERENT alternatives
3. ✅ Compare works → Shows side-by-side analysis
4. ✅ Buy Now works → Opens Shopee/Lazada
5. ✅ Wishlist works → Saves to Firebase
6. ✅ Filters work → Results update in real-time
7. ✅ Recent Activity works → "View Better Alternatives" button
8. ✅ Console shows emoji logs → Easy debugging
9. ✅ Screen shows "Source: Gemini AI ✨" → Confirms AI working

**If all tests pass, the implementation is COMPLETE! 🚀**
