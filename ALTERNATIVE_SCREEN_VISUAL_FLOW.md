# Alternative Screen Flow - Visual Guide

## 📱 Screen Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         SCAN SCREEN                              │
│                                                                   │
│  User scans product via:                                         │
│  • Barcode Scanner                                               │
│  • Image Recognition                                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      RESULT SCREEN                               │
│                                                                   │
│  Shows analysis:                                                 │
│  • Product Name                                                  │
│  • Eco Score (A+ to E)                                          │
│  • Carbon Footprint                                              │
│  • Disposal Method                                               │
│                                                                   │
│  [Button: Find Better Alternative] ◄── User taps                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                 NEW_ALTERNATIVE_SCREEN                           │
│                  (Generation Screen)                             │
│                                                                   │
│  1. Extract generic product type                                 │
│     "Colgate Total 150g" → "Toothpaste"                         │
│                                                                   │
│  2. Search for alternatives:                                     │
│     Priority 1: Firestore Cache (instant)                        │
│     Priority 2: Gemini AI (intelligent, 5-8 products)           │
│     Priority 3: Cloudinary JSON (fallback)                       │
│                                                                   │
│  3. Display alternatives in e-commerce layout:                   │
│     ┌──────────────────────────────────────┐                    │
│     │ [Image] Product Name        [❤️]     │                    │
│     │ Eco Score: A+ | Category            │                    │
│     │ "Uses biodegradable materials..."   │                    │
│     │ 💚 Saves 5kg CO₂/year               │                    │
│     │ [Compare] [Buy Now] [Wishlist]      │                    │
│     └──────────────────────────────────────┘                    │
│                                                                   │
│  Features:                                                       │
│  • Filter by price, brand, rating                               │
│  • Compare with scanned product                                  │
│  • Add to wishlist                                               │
│                                                                   │
│  ⚙️  ON EXIT (dispose/back button):                             │
│      → AUTOMATICALLY SAVES TO HISTORY                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Auto-save to Firestore:
                         │ /users/{userId}/alternative_history/{id}
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   ALTERNATIVE SCREEN                             │
│                    (History View)                                │
│                                                                   │
│  📚 Shows all previous alternative searches                      │
│                                                                   │
│  ┌─────────────────────────────────────────────┐                │
│  │ 🛍️ Your Eco Journey                        │                │
│  │ Review your sustainable choices             │                │
│  │ 💚 12 searches saved                        │                │
│  └─────────────────────────────────────────────┘                │
│                                                                   │
│  History Cards:                                                  │
│  ┌──────────────────────────────────────────┐                   │
│  │ [Icon] Colgate Toothpaste       [🗑️]     │                   │
│  │ Eco: C | Personal Care                   │                   │
│  │ ────────────────────────────────────     │                   │
│  │ 💚 5 better alternatives found            │                   │
│  │ 🕐 2h ago | Source: Gemini AI            │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                   │
│  ┌──────────────────────────────────────────┐                   │
│  │ [Icon] Nestle Coffee Mix        [🗑️]     │                   │
│  │ Eco: D | Food & Beverage                 │                   │
│  │ ────────────────────────────────────     │                   │
│  │ 💚 7 better alternatives found            │                   │
│  │ 🕐 1d ago | Source: Firestore Cache      │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                   │
│  Actions:                                                        │
│  • Tap card → View alternatives again                           │
│  • Tap 🗑️ → Delete from history                                 │
│  • Pull down → Refresh history                                   │
│                                                                   │
│  Empty State (no history):                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │         📜 (large icon)                  │                   │
│  │   No Alternative History Yet             │                   │
│  │                                          │                   │
│  │   Scan a product and find better        │                   │
│  │   alternatives to start building your   │                   │
│  │   eco-history!                           │                   │
│  │                                          │                   │
│  │   [🔍 Scan a Product]                    │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### Alternative Generation Flow
```
User Action: "Find Better Alternative"
        │
        ▼
NewAlternativeScreen.initState()
        │
        ├─► _generateAlternativesThenFallback()
        │   │
        │   ├─► Step 1: _tryFirestoreAlternatives()
        │   │   ├─► Query: sourceProductKey = "toothpaste"
        │   │   ├─► Found? → Display & STOP ✅
        │   │   └─► Not found? → Continue ↓
        │   │
        │   ├─► Step 2: _tryGeminiAlternatives()
        │   │   ├─► Send prompt to Gemini AI
        │   │   ├─► Parse JSON response (5-8 products)
        │   │   ├─► Save to Firestore cache
        │   │   ├─► Success? → Display & STOP ✅
        │   │   └─► Failed? → Continue ↓
        │   │
        │   └─► Step 3: _loadAlternativesIfNeeded()
        │       ├─► Fetch from Cloudinary JSON
        │       ├─► Found? → Display ✅
        │       └─► Not found? → Show empty state ❌
        │
        ▼
Display Alternatives (ranked by Eco Score → Name → Price)
```

### History Saving Flow
```
User exits NewAlternativeScreen
        │
        ├─► WillPopScope: onWillPop() → _saveToHistory()
        │   OR
        └─► dispose() → _saveToHistory()
                │
                ▼
        Create AlternativeHistory object:
        {
          scannedProduct: ProductAnalysisData,
          alternatives: List<AlternativeProduct>,
          createdAt: DateTime.now(),
          userId: currentUser.uid,
          dataSource: "Gemini AI"
        }
                │
                ▼
        Save to Firestore:
        /users/{userId}/alternative_history/{timestamp}
                │
                ▼
        History appears in Alternative Screen ✅
```

## 🎯 Key Features

### NewAlternativeScreen (Generation)
- ✅ Intelligent product type extraction
- ✅ Multi-source alternative search
- ✅ E-commerce style product cards
- ✅ Real-time filtering (price, brand, rating)
- ✅ Product comparison modal
- ✅ Wishlist integration
- ✅ **Automatic history saving on exit**

### Alternative Screen (History)
- ✅ Chronological history display
- ✅ Smart timestamp formatting ("2h ago", "3d ago")
- ✅ Eco score badges
- ✅ Alternative count display
- ✅ Data source indicator
- ✅ Delete individual items
- ✅ Pull-to-refresh
- ✅ Empty state with CTA
- ✅ Tap to revisit alternatives

## 📊 Ranking Algorithm

Alternatives are ranked by:

1. **Eco Score** (Priority 1)
   - A+ (best) → A → B → C → D → E (worst)
   
2. **Product Name Length** (Priority 2)
   - Shorter name = more generic/relevant
   - "Bamboo Toothbrush" ranks higher than "Eco Bamboo Toothbrush Pro Max 360°"

3. **Price** (Priority 3)
   - Lower price ranks higher
   - Products without price come last

Example ranking:
```
1. Bamboo Toothbrush         | Eco: A+  | RM 5.90
2. Charcoal Toothbrush        | Eco: A+  | RM 7.50
3. Eco Bamboo Brush Premium   | Eco: A+  | RM 12.00
4. Natural Bristle Brush      | Eco: A   | RM 4.50
5. Organic Wood Toothbrush    | Eco: A   | RM 6.00
```

## 🎨 UI/UX Highlights

### History Card Design
```
┌────────────────────────────────────────────┐
│ [🛍️ Icon]  Product Name           [🗑️]     │
│             Eco: A+ | Category             │
│ ──────────────────────────────────────     │
│ 💚 5 alternatives • 🕐 2h ago              │
│ Source: Gemini AI                          │
└────────────────────────────────────────────┘
```

### Empty State Design
```
┌────────────────────────────────────────────┐
│                                            │
│              📜 (80px icon)                │
│                                            │
│       No Alternative History Yet           │
│                                            │
│   Scan a product and find better          │
│   alternatives to start building           │
│   your eco-history!                        │
│                                            │
│      [🔍 Scan a Product]                   │
│                                            │
└────────────────────────────────────────────┘
```

## 🔧 Technical Implementation

### Auto-Save Mechanism
```dart
class _NewAlternativeScreenState extends State<NewAlternativeScreen> {
  @override
  void dispose() {
    _saveToHistory(); // Save before disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveToHistory(); // Save on back press
        return true;
      },
      child: Scaffold(/* ... */),
    );
  }
}
```

### Smart Timestamp
```dart
String _formatDate(DateTime date) {
  final difference = DateTime.now().difference(date);
  
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}
```

## 🚀 Usage Examples

### Scanning and Finding Alternatives
1. Open app → Navigate to Scan Screen
2. Scan "Colgate Total 150g Toothpaste"
3. View result → Tap "Find Better Alternative"
4. See loading → Gemini generates 7 alternatives
5. Browse, compare, filter alternatives
6. Press back → **Auto-saved to history**

### Viewing History
1. Navigate to Alternative Screen (tab 2)
2. See list of 12 previous searches
3. Tap "Colgate Toothpaste" card
4. View same 7 alternatives instantly (cached)
5. No re-generation needed!

### Managing History
1. Long press or tap 🗑️ on history card
2. Confirm deletion
3. Item removed from Firestore and UI
4. History updated in real-time
