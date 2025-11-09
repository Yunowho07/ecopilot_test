# 📊 EcoPilot Database Schema Documentation

## Database Structure Overview

This document describes the complete Firestore database structure for the EcoPilot application, following the official database diagram.

---

## 🗄️ Collections & Tables

### 1. Users Collection
**Collection Path:** `/users/{userId}`

**Purpose:** Stores user profile information, eco points, rank, and streak data.

**Important Note:** The document ID (`userId`) is the Firebase Auth UID (e.g., `zRnbn9VTvZepTcPiopeUymfoSn42`), which is the secure and recommended approach. A separate `username` field provides a human-readable identifier.

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `userId` | String | ✅ | Firebase Auth UID (document ID) - secure, immutable |
| `username` | String | ✅ | Human-readable username (auto-generated from name/email) |
| `name` | String | ✅ | User's display name |
| `email` | String | ✅ | User's email address |
| `profileImageUrl` | String | ❌ | URL to user's profile picture |
| `ecoPoints` | Number | ✅ | Total eco points earned (default: 0) |
| `rank` | String | ✅ | Current eco rank (default: "Green Beginner") |
| `streakCount` | Number | ✅ | Current daily streak (default: 0) |
| `totalChallengesCompleted` | Number | ✅ | Total challenges completed (default: 0) |
| `dateJoined` | Timestamp | ✅ | Account creation date |
| `updatedAt` | Timestamp | ✅ | Last update timestamp |

**Why Use UID as Document ID?**
- 🔒 **Security:** UIDs are unique and unpredictable
- 🔄 **Immutable:** Never changes, even if username/email changes
- ⚡ **Performance:** Direct document access by UID is faster
- 🛡️ **Privacy:** Firestore security rules use `request.auth.uid`

**Indexes:**
- `ecoPoints` (descending) - for leaderboard queries
- `rank` - for rank-based filtering

**Subcollections:**
- `point_history/{historyId}` - Individual point awards
- `monthly_points/{monthKey}` - Monthly point tracking
- `scans/{scanId}` - Product scans
- `disposal_scans/{scanId}` - Disposal guidance scans

---

### 2. Scanned Products Collection
**Collection Path:** `/scanned_products/{productId}`

**Purpose:** Stores products scanned through the main scan screen.

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `productId` | String | ✅ | Auto-generated document ID |
| `userId` | String | ✅ | Reference to Users collection |
| `productName` | String | ✅ | Name of the product |
| `category` | String | ❌ | Product category |
| `ingredients` | String | ❌ | Product ingredients list |
| `ecoScore` | String | ✅ | Eco-friendliness rating (A-E) |
| `carbonFootprint` | Number | ❌ | Carbon footprint value |
| `packagingType` | String | ❌ | Packaging material |
| `disposalMethod` | String | ❌ | How to dispose of product |
| `containsMicroplastics` | Boolean | ❌ | Microplastics indicator |
| `palmOilDerivative` | Boolean | ❌ | Palm oil content indicator |
| `crueltyFree` | Boolean | ❌ | Cruelty-free status |
| `imageUrl` | String | ❌ | Product image URL (Cloudinary) |
| `scanType` | String | ✅ | Scan method (manual, barcode, image) |
| `timestamp` | Timestamp | ✅ | Scan date and time |

**Indexes:**
- `userId` + `timestamp` (descending) - user's recent scans
- `ecoScore` - for filtering by eco rating
- `category` - for category-based queries

**Foreign Keys:**
- `userId` → `/users/{userId}`

---

### 3. Disposal Products Collection
**Collection Path:** `/disposal_products/{disposalId}`

**Purpose:** Stores products scanned for disposal guidance.

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `disposalId` | String | ✅ | Auto-generated document ID |
| `userId` | String | ✅ | Reference to Users collection |
| `productName` | String | ✅ | Name of the product |
| `material` | String | ✅ | Material type (plastic, glass, metal, etc.) |
| `ecoScore` | String | ❌ | Environmental impact rating |
| `howToDispose` | String | ✅ | Disposal instructions |
| `ecoTips` | Array | ❌ | List of eco-friendly tips |
| `nearbyRecyclingCenter` | String | ❌ | Nearby recycling facility |
| `imageUrl` | String | ❌ | Product image URL |
| `timestamp` | Timestamp | ✅ | Scan date and time |

**Indexes:**
- `userId` + `timestamp` (descending) - user's disposal history
- `material` - for material-based queries

**Foreign Keys:**
- `userId` → `/users/{userId}`

---

### 4. Alternative Products Collection
**Collection Path:** `/alternative_products/{alternativeId}`

**Purpose:** Stores eco-friendly product alternatives.

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `alternativeId` | String | ✅ | Auto-generated document ID |
| `baseProductId` | String | ✅ | Original product reference |
| `name` | String | ✅ | Alternative product name |
| `ecoScore` | String | ✅ | Eco-friendliness rating (A-E) |
| `description` | String | ❌ | Product description |
| `imageUrl` | String | ❌ | Product image URL |
| `buyUrl` | String | ❌ | Purchase link |
| `category` | String | ❌ | Product category |
| `timestamp` | Timestamp | ✅ | Creation date |

**Indexes:**
- `baseProductId` - for finding alternatives
- `category` - for category-based alternatives
- `ecoScore` - for high-rated alternatives

**Foreign Keys:**
- `baseProductId` → `/scanned_products/{productId}`

---

### 5. Eco Challenges Collection
**Collection Path:** `/eco_challenges/{challengeId}`

**Purpose:** Stores daily eco challenges available to all users.

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `challengeId` | String | ✅ | Auto-generated document ID |
| `title` | String | ✅ | Challenge title |
| `description` | String | ✅ | Challenge description |
| `pointsReward` | Number | ✅ | Points awarded on completion |
| `dateAvailable` | Timestamp | ✅ | When challenge is available |
| `isActive` | Boolean | ✅ | Whether challenge is active |

**Indexes:**
- `dateAvailable` + `isActive` - for fetching daily challenges
- `isActive` - for active challenges only

---

### 6. User Challenges Collection
**Collection Path:** `/user_challenges/{userId}-{challengeId}`

**Purpose:** Tracks individual user progress on challenges.

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `userId` | String | ✅ | Reference to Users collection |
| `challengeId` | String | ✅ | Reference to Eco Challenges |
| `isCompleted` | Boolean | ✅ | Completion status |
| `completedDate` | Timestamp | ❌ | When challenge was completed |
| `pointsEarned` | Number | ✅ | Points earned from challenge |
| `date` | Timestamp | ✅ | Challenge date |
| `updatedAt` | Timestamp | ✅ | Last update timestamp |

**Document ID Format:** `{userId}-{challengeId}` or `{userId}-{date}`

**Indexes:**
- `userId` + `date` (descending) - user's challenge history
- `userId` + `isCompleted` - completed challenges
- `challengeId` - all users who attempted a challenge

**Foreign Keys:**
- `userId` → `/users/{userId}`
- `challengeId` → `/eco_challenges/{challengeId}`

---

### 7. Eco Point History Collection
**Collection Path:** `/eco_point_history/{historyId}`

**Purpose:** Global audit log of all point awards (also stored in user subcollection).

**Fields:**
| Field Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `userId` | String | ✅ | Reference to Users collection |
| `source` | String | ✅ | Point source (scan, challenge, streak, bonus) |
| `pointsEarned` | Number | ✅ | Number of points awarded |
| `dateEarned` | Timestamp | ✅ | When points were awarded |
| `description` | String | ❌ | Additional context |

**Also stored in:** `/users/{userId}/point_history/{historyId}`

**Indexes:**
- `userId` + `dateEarned` (descending) - user's point timeline
- `source` - points by category
- `dateEarned` - global point timeline

**Foreign Keys:**
- `userId` → `/users/{userId}`

**Point Sources:**
- `scan` - Product scanning (+2 points)
- `challenge` - Challenge completion (+5-10 points)
- `streak_10` - 10-day streak bonus (+5 points)
- `streak_30` - 30-day streak bonus (+15 points)
- `streak_100` - 100-day streak bonus (+30 points)
- `streak_200` - 200-day streak bonus (+50 points)
- `disposal` - Following disposal guidance (+3 points)
- `alternative` - Exploring alternatives (+5 points)
- `tip` - Reading eco tips (+2-5 points)
- `quiz` - Completing quizzes (+2-5 points)
- `weekly` - Weekly engagement (+10 points)
- `leaderboard` - Monthly leaderboard bonus (up to +20 points)

---

## 🔗 Relationships

### One-to-Many Relationships

1. **Users → Scanned Products**
   - One user can have many scanned products
   - Foreign key: `scannedProducts.userId` → `users.userId`

2. **Users → Disposal Products**
   - One user can have many disposal products
   - Foreign key: `disposalProducts.userId` → `users.userId`

3. **Users → User Challenges**
   - One user can have many challenge attempts
   - Foreign key: `userChallenges.userId` → `users.userId`

4. **Users → Eco Point History**
   - One user can have many point history records
   - Foreign key: `ecoPointHistory.userId` → `users.userId`

5. **Scanned Products → Alternative Products**
   - One scanned product can have many alternatives
   - Foreign key: `alternativeProducts.baseProductId` → `scannedProducts.productId`

6. **Eco Challenges → User Challenges**
   - One challenge can be attempted by many users
   - Foreign key: `userChallenges.challengeId` → `ecoChallenges.challengeId`

---

## 📁 Subcollections

### Users Subcollections

1. **`/users/{userId}/point_history/{historyId}`**
   - Duplicate of global point history for faster queries
   - Same structure as `eco_point_history` collection

2. **`/users/{userId}/monthly_points/{monthKey}`**
   - Monthly point tracking (format: YYYY-MM)
   - Fields: `points`, `goal`, `month`, `updatedAt`

3. **`/users/{userId}/scans/{scanId}`**
   - User's personal scan history
   - Same structure as `scanned_products`

4. **`/users/{userId}/disposal_scans/{scanId}`**
   - User's disposal scan history
   - Same structure as `disposal_products`

---

## 🔒 Security Rules Summary

### Users Collection
- ✅ Read: Any authenticated user (for leaderboard)
- ✅ Write: Only the user themselves

### Scanned Products
- ✅ Read: Any authenticated user
- ✅ Write: Only the user who owns the scan

### Disposal Products
- ✅ Read: Any authenticated user
- ✅ Write: Only the user who owns the scan

### Alternative Products
- ✅ Read: Any authenticated user
- ❌ Write: Admin only (Cloud Functions)

### Eco Challenges
- ✅ Read: Any authenticated user
- ❌ Write: Admin only (Cloud Functions)

### User Challenges
- ✅ Read: Only the user themselves
- ✅ Write: Only the user themselves

### Eco Point History
- ✅ Read: Only the user themselves
- ✅ Write: Only the user themselves

---

## 🔍 Common Queries

### Get User's Recent Scans
```dart
FirebaseFirestore.instance
  .collection('scanned_products')
  .where('userId', isEqualTo: userId)
  .orderBy('timestamp', descending: true)
  .limit(10)
  .get();
```

### Get Today's Challenges
```dart
final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
FirebaseFirestore.instance
  .collection('eco_challenges')
  .where('isActive', isEqualTo: true)
  .where('dateAvailable', isEqualTo: today)
  .get();
```

### Get Leaderboard (Top 50)
```dart
FirebaseFirestore.instance
  .collection('users')
  .orderBy('ecoPoints', descending: true)
  .limit(50)
  .get();
```

### Get User's Point History
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('point_history')
  .orderBy('dateEarned', descending: true)
  .get();
```

### Get Alternatives for Product
```dart
FirebaseFirestore.instance
  .collection('alternative_products')
  .where('baseProductId', isEqualTo: productId)
  .get();
```

---

## 📈 Data Flow Examples

### Product Scan Flow
1. User scans product → Create document in `scanned_products`
2. Award 2 points → Create document in `eco_point_history`
3. Update user's `ecoPoints` in `users` collection
4. Check if rank changed → Update `rank` in `users`
5. Add to user's `scans` subcollection

### Challenge Completion Flow
1. User completes challenge → Update `user_challenges` document
2. Award points (5-10) → Create document in `eco_point_history`
3. Update user's `ecoPoints` and `totalChallengesCompleted`
4. Check if all challenges completed → Award bonus points
5. Update streak if applicable → Check streak milestones

### Streak Bonus Flow
1. Check user's last activity date
2. If consecutive day → Increment `streakCount`
3. Check milestone (10, 30, 100, 200 days)
4. Award bonus points → Create `eco_point_history` record
5. Update user's total `ecoPoints`

---

## 🛠️ Implementation Files

### Model Definitions
- `lib/models/database_models.dart` - All data models

### Service Layer
- `lib/services/database_service.dart` - CRUD operations

### Firebase Integration
- `lib/auth/firebase_service.dart` - Auth + points system
- `firestore.rules` - Security rules

---

## 📊 Storage Estimates

**Per User (1 year active use):**
- User profile: ~1 KB
- Product scans (~365): ~73 KB
- Disposal scans (~50): ~10 KB
- Challenge history (~730): ~15 KB
- Point history (~1000): ~20 KB
- **Total per user/year: ~120 KB**

**For 10,000 users:**
- Total data: ~1.2 GB
- Firestore free tier: 1 GB/month
- Estimated cost after free tier: $0.18/GB/month

---

## 🔄 Maintenance

### Daily Tasks
- Generate new daily challenges
- Check and reset user streaks
- Calculate monthly leaderboard bonuses

### Weekly Tasks
- Award weekly engagement bonuses
- Clean up inactive challenges

### Monthly Tasks
- Calculate monthly leaderboard rankings
- Award top performer bonuses
- Archive old point history (optional)

---

**Last Updated:** November 9, 2025  
**Version:** 1.0  
**Status:** ✅ Fully Implemented
