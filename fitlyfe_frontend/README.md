# FitLyfe Frontend

A Flutter project for the FitLyfe application.

## Recent Updates

### Nutrition & Meal Tracking Enhancements
- **Refined UI**: Removed empty action menus from the Add Food app bars for a cleaner appearance.
- **Improved Font Rendering**: Prevented scrolling from thickening the UI text by utilizing `scrolledUnderElevation` & `surfaceTintColor: Colors.transparent` fixes.
- **Crisp Text Overlays**: Fixed bottom sheet semi-transparent background (`barrierColor`) from washing out flutter's subpixel antialiasing for text underneath.
- **Dynamic Feedback Animations**: Replaced traditional "Added successfully" SnackBars with an elegant, bouncing animation effect on the "Just Added" header when logging foods.

### Global Meal Management
- **Global Settings Control**: Introduced `updateMealGlobally`, making meal icon and name changes cascade to all past dates, replacing manual iteration configurations!
- **Instant Icon Picker**: The Emoji/Icon picker now immediately synchronizes custom icons backward and forward across all screens upon tapping.

### Smooth User Navigation
- **Guided Tracking Flow**: When editing an existing established meal, pressing "Track now" bridges users explicitly into the search sheet targeted accurately for that exact meal type.
- **Elegant Page Transitions**: Replaced standard harsh instant jumps with an elegant custom `PageRouteBuilder` (utilizing a precise `SlideTransition` + `FadeTransition`).

### Add Food Search UI
- **Barcode Scanner Support**: Built native QR / EAN barcode support utilizing `simple_barcode_scanner` seamlessly integrated inside the "Add Foods" search bar suffix icon.
- **Enhanced Menus**: Upgraded the "Add Vitamin" dialog input dropdowns and fields to clean, rounded `OutlineInputBorder` aesthetics mirroring button radiuses.
