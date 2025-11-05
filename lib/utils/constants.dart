// lib/utils/constants.dart

import 'package:flutter/material.dart';

// Theme Color
const Color kPrimaryGreen = Color(0xFF1db954);
const Color kPrimaryYellow = Color(0xFFFFC300); // Used for the tips/highlights

// Additional shared colors used across screens
const Color kResultCardGreen = Color(0xFF388E3C);
const Color kWarningRed = Color(0xFFD32F2F);
const Color kDiscoverMoreYellow = Color(0xFFFDD835);
const Color kDiscoverMoreBlue = Color(0xFF1976D2);
const Color kDiscoverMoreGreen = kPrimaryGreen;

// Asset Paths
const String kLogoAsset = 'assets/ecopilot_logo.png';
const String kLogoWhiteAsset = 'assets/ecopilot_logo_white.png';

// Rank colors (theme-aware)
const Color kRankPlanetGuardian = Color(0xFF6A1B9A); // Purple
const Color kRankSustainabilityHero = Color(0xFFF57C00); // Orange
const Color kRankEcoChampion = kDiscoverMoreBlue; // Blue
const Color kRankSustainabilityAlly =
    kDiscoverMoreGreen; // Light green / theme green
const Color kRankGreenExplorer = kPrimaryGreen; // Base green

// New rank colors for Eco Point tiers
const Color kRankGreenBeginner = kPrimaryGreen; // 0-50
const Color kRankEcoExplorer = Color(0xFFFFC107); // 51-150 (amber)
const Color kRankPlanetProtector = Color(0xFF388E3C); // 151-300 (dark green)
// kRankSustainabilityHero already existed; keep it for 301+
