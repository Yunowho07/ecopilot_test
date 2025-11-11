# 🚀 Quick Start: Gemini Alternatives System

## ⚡ Deploy in 2 Minutes

### Step 1: Deploy Firestore Rules (Required)
```bash
firebase deploy --only firestore:rules
```

### Step 2: Deploy Firestore Indexes (Required)
```bash
firebase deploy --only firestore:indexes
```

### Step 3: Test!
```bash
flutter run
```

---

## 🎯 How to Test

1. **Scan a Product** (e.g., Coca-Cola can)
2. **Wait 3-5 seconds** for Gemini to generate alternatives
3. **Check Firestore Console** → `alternative_products` collection should populate
4. **Scan Same Product Again** → Should load instantly from cache!

---

## 📊 What to Monitor

### Firestore Console
- Collection: `alternative_products`
- Should see documents with:
  - `sourceProductKey` (e.g., "coca_cola_330ml_can")
  - `generatedAt` timestamp
  - `externalSource: "gemini"`

### App Logs (Debug Mode)
```
🔄 Starting alternative generation for: Coca-Cola 330ml Can
📍 Step 1: Checking Firestore cache...
🔍 Searching Firestore for cached alternatives...
❌ No alternatives found in Firestore
📍 Step 2: Trying Gemini AI (no cache found)...
🤖 Trying Gemini AI for alternatives... (Attempt 1/3)
📤 Sending request to Gemini...
✅ Gemini response received (2845 chars)
🔍 Parsing JSON...
✅ JSON parsed successfully, found 6 items
💾 Saving 6 alternatives to Firestore...
✅ Successfully saved alternatives to Firestore
✅ Success! Using Gemini AI alternatives (saved to cache)
```

**Next scan (with cache):**
```
🔄 Starting alternative generation for: Coca-Cola 330ml Can
📍 Step 1: Checking Firestore cache...
🔍 Searching Firestore for cached alternatives...
   Trying product-specific cache: coca_cola_330ml_can
✅ Found 6 alternatives in Firestore
✅ Success! Using cached Firestore alternatives
```

---

## 🐛 Troubleshooting

### Problem: No alternatives shown
**Solution:** Check `GEMINI_API_KEY` in `.env` file

### Problem: Firestore permission denied
**Solution:** Run `firebase deploy --only firestore:rules`

### Problem: Alternatives not caching
**Solution:** 
1. Check Firestore Console → `alternative_products` collection
2. Run `firebase deploy --only firestore:indexes`
3. Check app logs for "💾 Saving alternatives..." message

### Problem: Slow performance
**Solution:** 
- First scan = 3-5s (Gemini generation) ← Normal!
- Repeat scans = <500ms (cache) ← Should be fast

---

## 💰 Cost Tracking

### Google Cloud Console
1. Go to: https://console.cloud.google.com/
2. Navigate to: **APIs & Services** → **Gemini API**
3. Check: **Quota** and **Usage**

### Expected Costs (with caching)
- First scan of new product: **$0.001**
- Subsequent scans (cached): **$0.00** (free!)
- 1000 unique products = **$1.00**
- Same 1000 products scanned 10,000 times = **Still $1.00!** 🎉

---

## ✅ Success Checklist

- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] Scanned a product
- [ ] Saw Gemini generation logs
- [ ] Alternatives appeared in Firestore
- [ ] Second scan loaded from cache
- [ ] UI shows data source badge
- [ ] Filters work (price, brand, rating)
- [ ] Wishlist saves correctly
- [ ] Buy links open Shopee/Lazada

---

## 📚 Documentation

- **Complete Guide:** `GEMINI_ALTERNATIVES_SYSTEM.md`
- **Summary:** `GEMINI_IMPLEMENTATION_SUMMARY.md`
- **This File:** `QUICK_START_GEMINI.md`

---

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `lib/screens/alternative_screen.dart` | Main implementation |
| `firestore.rules` | Security rules |
| `firestore.indexes.json` | Database indexes |
| `setup_gemini_alternatives.bat` | Auto-deploy script |

---

## 🔥 Pro Tips

1. **Pre-populate Cache:** Scan popular products manually to cache for all users
2. **Monitor Costs:** Check Google Cloud Console weekly
3. **Debug Logs:** Enable in debug mode to see full flow
4. **Offline Testing:** Cached alternatives work offline!
5. **User Engagement:** Encourage users to add to wishlist (more data!)

---

**Last Updated:** November 12, 2025  
**System Status:** ✅ Production Ready  
**Total Setup Time:** ~2 minutes  
