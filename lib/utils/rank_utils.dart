import 'package:flutter/material.dart';
import 'package:ecopilot_test/utils/constants.dart';

/// Small value object for user rank display.
class RankInfo {
  final String title;
  final Color color;
  const RankInfo(this.title, this.color);
}

/// Compute a user rank and display color from their accumulated eco points.
RankInfo rankForPoints(int points) {
  if (points >= 1000)
    return const RankInfo('Planet Guardian', kRankPlanetGuardian);
  if (points >= 600)
    return const RankInfo('Sustainability Hero', kRankSustainabilityHero);
  if (points >= 300) return const RankInfo('Eco Champion', kRankEcoChampion);
  if (points >= 100)
    return const RankInfo('Sustainability Ally', kRankSustainabilityAlly);
  return const RankInfo('Green Explorer', kRankGreenExplorer);
}
