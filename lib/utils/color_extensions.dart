import 'package:flutter/material.dart';

// Helper to create a new [Color] with the requested [opacity]
// avoiding use of the deprecated `withOpacity`.
Color colorWithOpacity(Color color, double opacity) {
  // Compute alpha 0..255, clamp to valid range and apply withAlpha
  int a = (opacity * 255).round();
  if (a < 0) a = 0;
  if (a > 255) a = 255;
  return color.withAlpha(a);
}
