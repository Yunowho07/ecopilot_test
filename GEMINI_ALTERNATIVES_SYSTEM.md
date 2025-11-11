# 🌿 Gemini AI Alternative Products System

## Overview

This system uses **Gemini 1.5 Flash AI** to generate eco-friendly product alternatives with intelligent **Firestore caching** to optimize performance and reduce API costs.

---

## 🔄 System Flow

```
User Scans Product
       ↓
┌──────────────────────────────────────┐
│ 1. Check Firestore Cache (Fastest)  │ ← Product-specific cache
└──────────────────────────────────────┘
       ↓ (if not found)
┌──────────────────────────────────────┐
│ 2. Generate with Gemini AI          │ ← AI-powered alternatives
│    (Save to Firestore for caching)  │
└──────────────────────────────────────┘
       ↓ (if Gemini fails)
┌──────────────────────────────────────┐
│ 3. Fallback to Cloudinary JSON      │ ← Static fallback data
└──────────────────────────────────────┘
       ↓
   Display Alternatives
```

---

## 📦 Data Flow

### Input (Scanned Product Data)
```dart
ProductAnalysisData {
  productName: "Coca-Cola 330ml Can"
  category: "Beverages"
  ecoScore: "D"
  packagingType: "Aluminum Can"
  ingredients: "Carbonated Water, Sugar..."
  carbonFootprint: "150g CO₂"
}
```

### Gemini AI Prompt
```
You are an expert eco-product recommender...

SCANNED PRODUCT:
- Name: Coca-Cola 330ml Can
- Category: Beverages
- Eco Score: D
- Packaging: Aluminum Can

TASK: Find 5-8 REAL eco-friendly alternatives on Shopee/Lazada Malaysia
```

### Gemini Response (JSON)
```json
[
  {
    "name": "Honest Organic Lemon Tea 500ml",
    "ecoScore": "A",
    "category": "Beverages",
    "material": "Recycled Glass Bottle",
    "shortDescription": "Organic ingredients, reusable glass bottle reduces 80% plastic waste",
    "buyUrl": "https://shopee.com.my/search?keyword=honest+organic+tea",
    "carbonSavings": "Reduces 120g CO₂ per bottle",
    "price": 12.90,
    "brand": "Honest Tea",
    "rating": 4.7
  },
  {
    "name": "Chatime Eco Cup Bubble Tea Kit",
    "ecoScore": "B",
    "category": "Beverages",
    "material": "Bamboo Fiber Cup + Reusable Straw",
    "shortDescription": "Zero plastic waste, refillable system, 90% less CO₂",
    "buyUrl": "https://lazada.com.my/products/chatime-eco-kit",
    "carbonSavings": "Reduces 200g CO₂/year",
    "price": 24.50,
    "brand": "Chatime",
    "rating": 4.5
  }
]
```

### Firestore Storage
```
/alternative_products/{productId}
{
  name: "Honest Organic Lemon Tea 500ml"
  ecoScore: "A"
  category: "Beverages"
  materialType: "Recycled Glass Bottle"
  shortDescription: "Organic ingredients..."
  buyLink: "https://shopee.com.my/..."
  carbonSavings: "Reduces 120g CO₂ per bottle"
  price: 12.90
  brand: "Honest Tea"
  rating: 4.7
  externalSource: "gemini"
  
  // Cache metadata
  sourceProductName: "Coca-Cola 330ml Can"
  sourceProductKey: "coca_cola_330ml_can"
  sourceCategory: "Beverages"
  sourceEcoScore: "D"
  generatedAt: Timestamp(2025-11-12)
  createdAt: Timestamp(2025-11-12)
}
```

---

## 🎯 Key Features

### 1. **Smart Caching Strategy**

#### Product-Specific Cache (Fastest)
```dart
// First attempt: exact product match
FirebaseFirestore.instance
  .collection('alternative_products')
  .where('sourceProductKey', isEqualTo: 'coca_cola_330ml_can')
  .limit(10)
  .get()
```

#### Category-Based Cache (Fallback)
```dart
// Second attempt: category match
FirebaseFirestore.instance
  .collection('alternative_products')
  .where('category', isEqualTo: 'Beverages')
  .orderBy('ecoScore')
  .limit(10)
  .get()
```

#### Top-Rated Alternatives (Final Fallback)
```dart
// Third attempt: best alternatives
FirebaseFirestore.instance
  .collection('alternative_products')
  .orderBy('rating', descending: true)
  .limit(10)
  .get()
```

### 2. **Automatic Gemini Caching**
When Gemini generates alternatives, they're automatically saved to Firestore:

```dart
await _saveAlternativesToFirestore(scanned, generated);
```

**Benefits:**
- ⚡ **Instant loading** for repeat scans (no API call needed)
- 💰 **Reduced API costs** (Gemini only called once per product)
- 📊 **Shared cache** across all users (community benefit)

### 3. **Retry Logic with Exponential Backoff**
```dart
Future<bool> _tryGeminiAlternatives(
  ProductAnalysisData scanned,
  {int retryCount = 0}
) async {
  const maxRetries = 2;
  
  try {
    // Attempt Gemini generation...
  } catch (e) {
    if (retryCount < maxRetries) {
      final delaySeconds = (retryCount + 1) * 2; // 2s, 4s, 6s
      await Future.delayed(Duration(seconds: delaySeconds));
      return _tryGeminiAlternatives(scanned, retryCount: retryCount + 1);
    }
  }
}
```

### 4. **Data Source Transparency**
Users can see where alternatives came from:
- 🤖 "Gemini AI" - Freshly generated
- 📦 "Firestore Cache (Product-Specific)" - Cached from previous scan
- ☁️ "Firestore Database" - Category/rating-based alternatives
- 📁 "Cloudinary" - Static JSON fallback

---

## 🛠️ Implementation Details

### File Structure
```
lib/
├── screens/
│   └── alternative_screen.dart       # Main UI & logic
├── models/
│   └── product_analysis_data.dart    # Scanned product model
└── services/
    └── generative_service.dart       # Gemini API wrapper
```

### Key Methods

#### 1. Main Generation Flow
```dart
Future<void> _generateAlternativesThenFallback() async {
  // Step 1: Check Firestore cache (instant)
  bool cached = await _tryFirestoreAlternatives(scanned);
  if (cached) return;
  
  // Step 2: Generate with Gemini (2-5 seconds)
  bool generated = await _tryGeminiAlternatives(scanned);
  if (generated) return;
  
  // Step 3: Cloudinary fallback (last resort)
  await _loadAlternativesIfNeeded();
}
```

#### 2. Gemini Generation
```dart
Future<bool> _tryGeminiAlternatives(ProductAnalysisData scanned) async {
  final prompt = '''
    Find 5-8 REAL eco-friendly alternatives for:
    Product: ${scanned.productName}
    Category: ${scanned.category}
    Current Eco Score: ${scanned.ecoScore}
    
    Return JSON array with: name, ecoScore, material, 
    buyUrl, price, brand, rating...
  ''';
  
  final response = await GenerativeService.generateResponse(prompt);
  final alternatives = parseAlternatives(response);
  
  // Save to Firestore for caching
  await _saveAlternativesToFirestore(scanned, alternatives);
  
  return alternatives.isNotEmpty;
}
```

#### 3. Firestore Caching
```dart
Future<void> _saveAlternativesToFirestore(
  ProductAnalysisData scanned,
  List<AlternativeProduct> alternatives,
) async {
  final batch = FirebaseFirestore.instance.batch();
  
  for (final alt in alternatives) {
    final docRef = FirebaseFirestore.instance
        .collection('alternative_products')
        .doc(alt.id);
    
    batch.set(docRef, {
      ...alt.toFirestore(),
      'sourceProductKey': productKey,
      'generatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  await batch.commit();
}
```

---

## 📊 Performance Metrics

| Data Source | Speed | API Cost | Accuracy |
|-------------|-------|----------|----------|
| **Firestore Cache** | ⚡ <200ms | $0 | ⭐⭐⭐⭐⭐ |
| **Gemini AI** | 🐢 2-5s | $0.001/call | ⭐⭐⭐⭐⭐ |
| **Cloudinary JSON** | ⚡ 500ms | $0 | ⭐⭐⭐ |

### Cost Optimization Example

**Without Caching:**
- 100 users scan "Coca-Cola" → 100 Gemini calls
- Cost: 100 × $0.001 = **$0.10**

**With Caching:**
- 1st user scan "Coca-Cola" → 1 Gemini call → Save to Firestore
- 99 other users → Read from Firestore (free)
- Cost: 1 × $0.001 = **$0.001** (99% savings! 💰)

---

## 🔐 Firestore Security Rules

```javascript
// Allow authenticated users to read alternatives
match /alternative_products/{productId} {
  allow read: if request.auth != null;
  
  // Allow creating alternatives (for Gemini caching)
  allow create: if request.auth != null
                && request.resource.data.keys().hasAll([
                  'name', 'ecoScore', 'category'
                ]);
  
  // Allow updates
  allow update: if request.auth != null;
  
  // Prevent deletion (admin-only via console)
  allow delete: if false;
}

// User wishlist
match /users/{userId}/wishlist/{productId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## 🎨 UI Features

### Alternative Product Card
```dart
AlternativeProductCard(
  product: alternative,
  isInWishlist: _wishlist.contains(alternative.id),
  onTap: () => _showAlternativeDetails(alternative),
  onBuyNow: () => _openBuyLink(alternative.buyLink),
  onAddToWishlist: () => _toggleWishlist(alternative),
  onCompare: () => _showComparison(alternative),
)
```

**Card displays:**
- 🖼️ Product image
- 📛 Product name & brand
- 🌿 Eco score badge (color-coded: A=Green, B=Yellow, C=Orange, D/E=Red)
- 📦 Material/packaging type
- 💰 Price (if available)
- ⭐ Rating (if available)
- 🛒 "Buy Now" button (opens Shopee/Lazada)
- ❤️ Wishlist toggle
- ⚖️ Compare button (vs scanned product)

### Filter System
```dart
// Filter by max price
if (_maxPrice != null) {
  filtered = filtered.where((p) => p.price! <= _maxPrice!).toList();
}

// Filter by brand
if (_selectedBrand != null) {
  filtered = filtered.where((p) => p.brand == _selectedBrand).toList();
}

// Filter by minimum rating
if (_minRating != null) {
  filtered = filtered.where((p) => p.rating! >= _minRating!).toList();
}
```

---

## 🚀 Usage Example

### 1. User scans Coca-Cola can
```dart
final scannedProduct = ProductAnalysisData(
  productName: "Coca-Cola 330ml Can",
  category: "Beverages",
  ecoScore: "D",
  packagingType: "Aluminum Can",
  carbonFootprint: "150g CO₂",
);
```

### 2. Navigate to Alternative Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AlternativeScreen(
      scannedProduct: scannedProduct,
    ),
  ),
);
```

### 3. System automatically:
- ✅ Checks Firestore cache (200ms)
- ✅ If not found → Calls Gemini (3s)
- ✅ Parses JSON response
- ✅ Saves to Firestore
- ✅ Displays 5-8 alternatives
- ✅ Shows "Source: Gemini AI"

### 4. Next user scans same product:
- ✅ Checks Firestore cache (200ms)
- ✅ Finds cached alternatives
- ✅ Displays instantly (no Gemini call!)
- ✅ Shows "Source: Firestore Cache (Product-Specific)"

---

## 🐛 Debugging

### Enable Debug Logs
All methods include detailed logging:

```
🔄 Starting alternative generation for: Coca-Cola 330ml Can
📍 Step 1: Checking Firestore cache...
🔍 Searching Firestore for cached alternatives...
   Trying product-specific cache: coca_cola_330ml_can
❌ No alternatives found in Firestore
📍 Step 2: Trying Gemini AI (no cache found)...
🤖 Trying Gemini AI for alternatives... (Attempt 1/3)
   Product: Coca-Cola 330ml Can
   Category: Beverages
   Eco Score: D
📤 Sending request to Gemini...
✅ Gemini response received (2845 chars)
🔍 Parsing JSON...
✅ JSON parsed successfully, found 6 items
   ✓ Adding alternative: Honest Organic Lemon Tea (A)
   ✓ Adding alternative: Chatime Eco Cup Kit (B)
   ...
💾 Saving 6 alternatives to Firestore...
✅ Successfully saved alternatives to Firestore
✅ Success! Using Gemini AI alternatives (saved to cache)
```

### Common Issues

#### Issue: Gemini returns empty response
**Solution:** Check `GEMINI_API_KEY` in `.env` file

#### Issue: Firestore permission denied
**Solution:** Deploy updated `firestore.rules` with:
```bash
firebase deploy --only firestore:rules
```

#### Issue: Alternatives not caching
**Solution:** Check Firestore console → `alternative_products` collection should populate after first Gemini call

---

## 📈 Future Enhancements

### Planned Features
- [ ] **User preference learning** - Personalize alternatives based on scan history
- [ ] **Collaborative filtering** - Recommend alternatives popular among similar users
- [ ] **Real-time price updates** - Scrape Shopee/Lazada for latest prices
- [ ] **Image generation** - Use Gemini to generate product images if missing
- [ ] **Sentiment analysis** - Analyze user reviews from e-commerce sites
- [ ] **Carbon impact calculator** - Real-time CO₂ savings comparison

---

## 📚 Related Documentation

- [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Firestore Caching Best Practices](https://firebase.google.com/docs/firestore/query-data/query-cursors)
- [Flutter Performance Optimization](https://docs.flutter.dev/perf)

---

## ✅ Checklist for New Products

Before deploying:

- [ ] Set `GEMINI_API_KEY` in `.env`
- [ ] Deploy Firestore security rules: `firebase deploy --only firestore:rules`
- [ ] Test with multiple products
- [ ] Verify Firestore caching works (check console)
- [ ] Test offline behavior
- [ ] Monitor Gemini API quota/costs
- [ ] Set up Firestore indexes if needed

---

## 💡 Tips

1. **Monitor API Costs:** Check Google Cloud Console → Gemini AI API usage
2. **Optimize Prompts:** Shorter prompts = faster responses + lower costs
3. **Cache Aggressively:** Most products won't change frequently
4. **Handle Errors Gracefully:** Always have Cloudinary JSON fallback
5. **Log Everything:** Debug logs help diagnose issues quickly

---

**Last Updated:** November 12, 2025  
**System Version:** 2.0  
**Gemini Model:** Gemini 1.5 Flash  
