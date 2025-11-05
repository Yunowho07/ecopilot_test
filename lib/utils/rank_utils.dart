import 'package:flutter/material.dart';
import 'package:ecopilot_test/utils/constants.dart';

/// Small value object for user rank display.
class RankInfo {
  final String title;
  final Color color;
  const RankInfo(this.title, this.color);
}

/// Eco Point tiers used by EcoPilot (implements the four requested ranks):
/// - 0–50: Green Beginner
/// - 51–150: Eco Explorer
/// - 151–300: Planet Protector
/// - 301+: Sustainability Hero
RankInfo rankForPoints(int points) {
  if (points >= 301)
    return const RankInfo('Sustainability Hero', kRankSustainabilityHero);
  if (points >= 151)
    return const RankInfo('Planet Protector', kRankPlanetProtector);
  if (points >= 51) return const RankInfo('Eco Explorer', kRankEcoExplorer);
  return const RankInfo('Green Beginner', kRankGreenBeginner);
}
