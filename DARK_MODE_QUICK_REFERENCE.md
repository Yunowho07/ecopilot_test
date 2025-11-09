# 🎨 Dark Mode Quick Reference Guide

## Common Color Replacements

Use this as a quick reference when updating screens to support dark mode.

---

## 📦 Background Colors

### Scaffold Background
```dart
// ❌ Before
Scaffold(
  backgroundColor: Colors.grey.shade50,
)

// ✅ After
Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
)
```

### Card Background
```dart
// ❌ Before
Container(
  color: Colors.white,
  decoration: BoxDecoration(
    color: Colors.white,
  ),
)

// ✅ After
Container(
  color: Theme.of(context).cardColor,
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
  ),
)
```

### Divider
```dart
// ❌ Before
Divider(color: Colors.grey.shade300)

// ✅ After
Divider(color: Theme.of(context).dividerColor)
```

---

## 📝 Text Colors

### Primary Text
```dart
// ❌ Before
Text(
  'Hello',
  style: TextStyle(color: Colors.black87),
)

// ✅ After
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyLarge,
)
```

### Secondary Text
```dart
// ❌ Before
Text(
  'Subtitle',
  style: TextStyle(color: Colors.grey.shade700),
)

// ✅ After
Text(
  'Subtitle',
  style: Theme.of(context).textTheme.bodyMedium,
)
```

### Heading
```dart
// ❌ Before
Text(
  'Title',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
)

// ✅ After
Text(
  'Title',
  style: Theme.of(context).textTheme.displaySmall,
)
```

---

## 🎯 AppBar

### Standard AppBar
```dart
// ❌ Before
AppBar(
  backgroundColor: kPrimaryGreen,
  foregroundColor: Colors.white,
)

// ✅ After - Option 1 (Use theme)
AppBar(
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
)

// ✅ After - Option 2 (Conditional)
final isDark = Theme.of(context).brightness == Brightness.dark;
AppBar(
  backgroundColor: isDark ? Theme.of(context).cardColor : kPrimaryGreen,
)
```

---

## 🔘 Buttons

### Elevated Button
```dart
// ❌ Before
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: kPrimaryGreen,
    foregroundColor: Colors.white,
  ),
  child: Text('Button'),
)

// ✅ After (uses theme automatically)
ElevatedButton(
  child: Text('Button'),
)
```

### Text Button
```dart
// ❌ Before
TextButton(
  style: TextButton.styleFrom(foregroundColor: kPrimaryGreen),
  child: Text('Button'),
)

// ✅ After
TextButton(
  child: Text('Button'), // Uses theme color
)
```

---

## 🎨 Icons

### Standard Icon
```dart
// ❌ Before
Icon(Icons.home, color: Colors.grey.shade700)

// ✅ After
Icon(Icons.home, color: Theme.of(context).iconTheme.color)
```

### Colored Icon
```dart
// Keep accent colors the same
Icon(Icons.eco, color: kPrimaryGreen) // ✅ OK - branding color
```

---

## 🖼️ Shadows & Elevation

### Box Shadow
```dart
// ❌ Before
BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
)

// ✅ After
final isDark = Theme.of(context).brightness == Brightness.dark;
BoxShadow(
  color: isDark 
      ? Colors.black.withOpacity(0.3)
      : Colors.black.withOpacity(0.05),
  blurRadius: 10,
)
```

---

## 🌈 Gradients

### Background Gradient
```dart
// ❌ Before
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
  ),
)

// ✅ After
final isDark = Theme.of(context).brightness == Brightness.dark;
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: isDark
        ? [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ]
        : [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
  ),
)
```

---

## 🎛️ Input Fields

### TextField
```dart
// ❌ Before
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade100,
  ),
)

// ✅ After (uses theme automatically)
TextField(
  decoration: InputDecoration(
    filled: true,
    // fillColor uses theme's inputDecorationTheme
  ),
)
```

---

## 🛡️ Borders

### Container Border
```dart
// ❌ Before
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
  ),
)

// ✅ After
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: Theme.of(context).colorScheme.outline,
    ),
  ),
)
```

---

## 💡 Utility Functions

### Check if Dark Mode
```dart
bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

// Usage
if (isDarkMode(context)) {
  // Dark mode specific logic
}
```

### Get Adaptive Color
```dart
Color getAdaptiveColor(
  BuildContext context, {
  required Color light,
  required Color dark,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? dark : light;
}

// Usage
color: getAdaptiveColor(
  context,
  light: Colors.white,
  dark: Color(0xFF1E1E1E),
)
```

---

## 📋 Screen Template

Complete example of a theme-aware screen:

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardColor : kPrimaryGreen,
        title: Text('My Screen'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Card
            Card(
              color: theme.cardColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Heading
                    Text(
                      'Title',
                      style: theme.textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8),
                    // Body text
                    Text(
                      'Description',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Button
            ElevatedButton(
              onPressed: () {},
              child: Text('Action'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Priority Order for Updating Screens

1. **Critical Screens** (Update First)
   - `home_screen.dart`
   - `setting_screen.dart`
   - `profile_screen.dart`

2. **High Priority**
   - `scan_screen.dart`
   - `result_screen.dart`
   - `leaderboard_screen.dart`

3. **Medium Priority**
   - `alternative_screen.dart`
   - `disposal_guidance_screen.dart`
   - `notification_screen.dart`

4. **Low Priority**
   - `support_screen.dart`
   - Auth screens (login, signup)
   - Onboarding screens

---

## 🔍 Finding Hardcoded Colors

Search for these patterns in your code:

```
Colors.white
Colors.black
Colors.grey
.shade[0-9]
Color(0xFF
rgba?\\(
```

---

## ✅ Testing Checklist

For each updated screen:

- [ ] Scaffold background adapts
- [ ] Cards/containers adapt
- [ ] Text is readable in both modes
- [ ] Icons are visible
- [ ] Shadows look good
- [ ] Gradients adapt or look good in both modes
- [ ] No pure white/black that blinds in dark mode
- [ ] Borders are visible
- [ ] Input fields are usable
- [ ] AppBar looks consistent

---

## 🎨 Color Palette Reference

### Light Mode
| Element | Color |
|---------|-------|
| Background | `#FAFAFA` (grey.shade50) |
| Card | `#FFFFFF` (white) |
| Text | `#000000DE` (black87) |
| Text Secondary | `#00000099` (black54) |
| Primary | `#1DB954` (kPrimaryGreen) |

### Dark Mode
| Element | Color |
|---------|-------|
| Background | `#121212` |
| Card | `#1E1E1E` |
| Text | `#FFFFFF` (white) |
| Text Secondary | `#FFFFFFB3` (white70) |
| Primary | `#1DB954` (kPrimaryGreen) |

---

**Last Updated:** November 9, 2025  
**Version:** 1.0  
**Reference Type:** Quick Guide
