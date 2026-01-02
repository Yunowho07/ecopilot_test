# Store Images Setup Guide 🖼️

## ✅ What I've Done:

1. ✅ Created `assets/stores/` folder
2. ✅ Updated `pubspec.yaml` to include store assets
3. ✅ Updated `redeem_screen.dart` to use local assets instead of URLs
4. ✅ Changed `Image.network` to `Image.asset`

## 📸 Next Steps - Save Your Images:

You need to **save the 12 store images** you provided into the `assets/stores/` folder with these EXACT filenames:

### Required Image Files:

Copy each image to: `c:\Flutter_Project\ecopilot_test\assets\stores\`

1. **99speedmart.jpg** - 99 Speedmart store photo
2. **kk_supermart.jpg** - KK Super Mart store photo  
3. **hero.jpg** - Hero Market store photo
4. **familymart.jpg** - Family Mart store photo
5. **econsave.jpg** - Econsave store photo
6. **mydin.jpg** - Mydin store photo
7. **lotus.jpg** - Lotus's Malaysia store photo
8. **giant.jpg** - Giant Hypermarket store photo
9. **aeon.jpg** - AEON store photo
10. **village_grocer.jpg** - Village Grocer store photo
11. **lulu.jpg** - Lulu Hypermarket store photo
12. **tf_value_mart.jpg** - TF Value-Mart store photo

### Missing Stores (optional - use generic placeholders):
- **thestore.jpg** - The Store
- **bataras.jpg** - Bataras Hypermarket
- **nsk.jpg** - NSK Trade City
- **pasaraya.jpg** - Pasaraya Sakan

## 🚀 How to Complete Setup:

1. **Save each image with the exact filename** listed above
2. Run: `flutter pub get` (to reload assets)
3. **Hot restart** your app (R in terminal or restart button)
4. Navigate to Redeem screen to see real store photos! 🎉

## 📝 Image Requirements:

- **Format**: JPG recommended (PNG also works)
- **Size**: Any size (Flutter will resize automatically)
- **Recommended**: 800x600 or similar aspect ratio
- **Naming**: MUST match exactly (case-sensitive on some systems)

## 🔧 If Images Don't Show:

1. Check filenames match EXACTLY
2. Run `flutter clean`
3. Run `flutter pub get`
4. Restart the app completely (hot restart)

## 📂 Expected Folder Structure:

```
c:\Flutter_Project\ecopilot_test\
├── assets/
│   └── stores/
│       ├── 99speedmart.jpg
│       ├── kk_supermart.jpg
│       ├── hero.jpg
│       ├── familymart.jpg
│       ├── econsave.jpg
│       ├── mydin.jpg
│       ├── lotus.jpg
│       ├── giant.jpg
│       ├── aeon.jpg
│       ├── village_grocer.jpg
│       ├── lulu.jpg
│       └── tf_value_mart.jpg
├── lib/
└── pubspec.yaml (✅ already updated)
```

## ✨ Result:

Once images are saved, each coupon card will display the **actual store photo** making your redemption screen look professional and authentic! 🏪✨
