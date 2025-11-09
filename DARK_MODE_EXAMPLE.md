# 🎨 Visual Example: Before & After Dark Mode

## Complete Working Example

This file shows exactly how to convert a screen to support dark mode.

---

## ❌ BEFORE (Hardcoded Colors)

```dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // ❌ Hardcoded
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white, // ❌ Hardcoded
        title: Text('My Screen'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87, // ❌ Hardcoded
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Here are your eco stats',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700, // ❌ Hardcoded
              ),
            ),
            
            SizedBox(height: 24),
            
            // Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // ❌ Hardcoded
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // ❌ Hardcoded
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco,
                        color: kPrimaryGreen, // ✅ OK - Brand color
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eco Points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87, // ❌ Hardcoded
                            ),
                          ),
                          Text(
                            '1,250 points',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600, // ❌ Hardcoded
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300), // ❌ Hardcoded
                  SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text('View Details'),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, // ❌ Hardcoded
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300, // ❌ Hardcoded
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: kPrimaryGreen,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Challenge Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87, // ❌ Hardcoded
                              ),
                            ),
                            Text(
                              '2 hours ago',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600, // ❌ Hardcoded
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ✅ AFTER (Theme-Aware)

```dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ Get theme reference
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Theme-aware
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardColor : kPrimaryGreen, // ✅ Adapts
        foregroundColor: theme.colorScheme.onPrimary, // ✅ Theme-aware
        title: Text('My Screen'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome Back!',
              style: theme.textTheme.displaySmall, // ✅ Uses theme style
            ),
            SizedBox(height: 8),
            Text(
              'Here are your eco stats',
              style: theme.textTheme.bodyMedium, // ✅ Uses theme style
            ),
            
            SizedBox(height: 24),
            
            // Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor, // ✅ Theme-aware
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05), // ✅ Adapts
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco,
                        color: kPrimaryGreen, // ✅ Brand color stays same
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eco Points',
                            style: theme.textTheme.titleLarge, // ✅ Theme style
                          ),
                          Text(
                            '1,250 points',
                            style: theme.textTheme.bodyMedium, // ✅ Theme style
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  Divider(color: theme.dividerColor), // ✅ Theme-aware
                  SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: () {},
                    // ✅ Uses theme button style automatically
                    child: Text('View Details'),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor, // ✅ Theme-aware
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline, // ✅ Theme-aware
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: kPrimaryGreen,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Challenge Completed',
                              style: theme.textTheme.titleMedium, // ✅ Theme
                            ),
                            Text(
                              '2 hours ago',
                              style: theme.textTheme.bodySmall, // ✅ Theme
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔍 Key Changes Summary

| Element | Before | After |
|---------|--------|-------|
| Scaffold BG | `Colors.grey.shade50` | `theme.scaffoldBackgroundColor` |
| Card BG | `Colors.white` | `theme.cardColor` |
| AppBar BG | `kPrimaryGreen` | `isDark ? theme.cardColor : kPrimaryGreen` |
| Primary Text | `Colors.black87` | `theme.textTheme.displaySmall` |
| Secondary Text | `Colors.grey.shade700` | `theme.textTheme.bodyMedium` |
| Divider | `Colors.grey.shade300` | `theme.dividerColor` |
| Border | `Colors.grey.shade300` | `theme.colorScheme.outline` |
| Shadow | Fixed opacity | `isDark ? 0.3 : 0.05` |

---

## 🎨 Visual Comparison

### Light Mode:
```
┌─────────────────────────────────┐
│  🟢 My Screen          [≡]      │ ← Green AppBar
├─────────────────────────────────┤
│                                 │
│  Welcome Back!                  │ ← Black text
│  Here are your eco stats        │ ← Grey text
│                                 │
│  ┌───────────────────────────┐ │
│  │ 🌿  Eco Points           │ │ ← White card
│  │     1,250 points          │ │
│  │ ────────────────────────  │ │
│  │   [View Details]          │ │ ← Green button
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ ✓ Challenge Completed     │ │ ← White card
│  │   2 hours ago             │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

### Dark Mode:
```
┌─────────────────────────────────┐
│  ⬛ My Screen          [≡]      │ ← Dark AppBar
├─────────────────────────────────┤
│                                 │
│  Welcome Back!                  │ ← White text
│  Here are your eco stats        │ ← Light grey text
│                                 │
│  ┌───────────────────────────┐ │
│  │ 🌿  Eco Points           │ │ ← Dark grey card
│  │     1,250 points          │ │
│  │ ────────────────────────  │ │
│  │   [View Details]          │ │ ← Green button
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ ✓ Challenge Completed     │ │ ← Dark grey card
│  │   2 hours ago             │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

---

## 💡 Pro Tips

### 1. Always get theme reference at the start:
```dart
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  // ... rest of your code
}
```

### 2. Keep brand colors consistent:
```dart
// ✅ Brand colors stay the same in both modes
Icon(Icons.eco, color: kPrimaryGreen)
```

### 3. Use conditional logic for special cases:
```dart
color: isDark ? Colors.grey.shade800 : Colors.grey.shade200
```

### 4. Prefer theme styles over manual styling:
```dart
// ❌ Less maintainable
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)

// ✅ More maintainable
style: theme.textTheme.displaySmall
```

---

## 🧪 Test Checklist

After converting your screen:

- [ ] Run app in light mode - looks good?
- [ ] Toggle to dark mode - everything visible?
- [ ] Text is readable in both modes?
- [ ] Cards have proper contrast?
- [ ] Icons are visible?
- [ ] Buttons work and look good?
- [ ] No pure white backgrounds blinding users in dark?
- [ ] No pure black backgrounds in light mode?

---

**This is a complete working example you can copy and modify!**

Created: November 9, 2025  
Use this as a template for updating your screens! 🚀
