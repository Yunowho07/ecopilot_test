# Alternative Screen Restructure Plan

## Overview
Restructure the alternative products feature to separate history viewing from active alternative generation.

## New Flow

### 1. Alternative Screen (History View)
**File**: `lib/screens/alternative_screen.dart`
- **Purpose**: Display history of past alternative product searches
- **State**: Empty state when no history exists, shows past searches when history exists
- **Features**:
  - Shows recent alternative searches with timestamps
  - Each history item displays the scanned product + alternatives found
  - Can tap to view full details again
  - Can delete history items

### 2. New Alternative Screen (Generation View)
**File**: `lib/screens/new_alternative_screen.dart`
- **Purpose**: Generate and display alternative products for a scanned item
- **Trigger**: When user clicks "Find Better Alternative" button from scan result screen
- **Features**:
  - E-commerce style layout
  - Product images, eco scores, prices
  - Comparison options
  - Buy now links
  - Wishlist functionality
- **On Exit**: Automatically save to history in Firestore

### 3. Scan Result Screen Integration
**File**: `lib/screens/result_screen.dart` (or wherever scan results are shown)
- **New Button**: "Find Better Alternative"
- **Action**: Navigate to `new_alternative_screen.dart` with scanned product data

## Firestore Schema

### Collection: `users/{uid}/alternative_history`
```json
{
  "scannedProduct": {
    "name": "string",
    "ecoScore": "string",
    "category": "string",
    "imagePath": "string"
  },
  "alternatives": [
    {
      "name": "string",
      "ecoScore": "string",
      "price": number,
      "imagePath": "string",
      ...
    }
  ],
  "searchedAt": timestamp,
  "alternativeCount": number
}
```

## Implementation Steps

1. ✅ Create `new_alternative_screen.dart` - Copy current alternative generation logic
2. ⬜ Modify `alternative_screen.dart` to be history view
3. ⬜ Add automatic history save when exiting new_alternative_screen
4. ⬜ Update navigation from scan/result screens
5. ⬜ Test the complete flow

## Benefits

- **Clearer UX**: Users understand they're viewing history vs generating new alternatives
- **Performance**: Don't regenerate alternatives every time screen is opened
- **History Tracking**: Users can review past comparisons
- **Better Organization**: Separation of concerns (history vs generation)
