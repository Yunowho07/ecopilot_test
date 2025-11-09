import 'package:flutter/material.dart';
import 'package:ecopilot_test/utils/constants.dart';

/// Small value object for user rank display.
class RankInfo {
  final String title;
  final Color color;
  final String emoji;
  final int minPoints;
  final int? maxPoints;

  const RankInfo(
    this.title,
    this.color,
    this.emoji,
    this.minPoints, [
    this.maxPoints,
  ]);
}

/// Eco Point Reward System - 8 Tier Ranking System
///
/// Points can be earned through:
/// - Product scanning (+2 points)
/// - Daily challenge completion (+5 per task, +10 for both)
/// - Streak bonuses (10 days: +5, 30 days: +15, 100 days: +30, 200 days: +50)
/// - Disposal guidance (+3 points)
/// - Exploring alternatives (+5 points)
/// - Reading tips/quizzes (+2-5 points)
/// - Weekly engagement (+10 points)
/// - Monthly leaderboard bonus (up to +20 points)
RankInfo rankForPoints(int points) {
  if (points >= 2000) {
    return const RankInfo(
      'Global Sustainability Icon',
      Color(0xFFFFD700), // Gold
      '🏆',
      2000,
      null,
    );
  }
  if (points >= 1201) {
    return const RankInfo(
      'Eco Legend',
      Color(0xFF9C27B0), // Purple
      '⭐',
      1201,
      2000,
    );
  }
  if (points >= 801) {
    return const RankInfo(
      'Climate Champion',
      Color(0xFFE91E63), // Pink
      '🔥',
      801,
      1200,
    );
  }
  if (points >= 501) {
    return const RankInfo(
      'Earth Guardian',
      Color(0xFF2196F3), // Blue
      '💧',
      501,
      800,
    );
  }
  if (points >= 301) {
    return const RankInfo(
      'Sustainability Hero',
      kRankSustainabilityHero, // Orange
      '🌎',
      301,
      500,
    );
  }
  if (points >= 151) {
    return const RankInfo(
      'Planet Protector',
      kRankPlanetProtector, // Dark Green
      '🌳',
      151,
      300,
    );
  }
  if (points >= 51) {
    return const RankInfo(
      'Eco Explorer',
      kRankEcoExplorer, // Amber
      '🌻',
      51,
      150,
    );
  }
  return const RankInfo(
    'Green Beginner',
    kRankGreenBeginner, // Primary Green
    '🌱',
    0,
    50,
  );
}

/// Get description for each rank tier
String getRankDescription(int points) {
  final rank = rankForPoints(points);

  switch (rank.title) {
    case 'Global Sustainability Icon':
      return 'The ultimate eco rank. You embody environmental leadership and inspire global change.';
    case 'Eco Legend':
      return 'You\'ve reached the elite level — your efforts have made a lasting mark on the planet\'s future.';
    case 'Climate Champion':
      return 'You lead by example, combining knowledge, action, and influence to protect the environment.';
    case 'Earth Guardian':
      return 'You actively reduce waste and carbon impact through consistent eco engagement.';
    case 'Sustainability Hero':
      return 'You\'ve made sustainability a daily commitment — inspiring others to do the same.';
    case 'Planet Protector':
      return 'You\'re taking real action to protect the planet through responsible decisions.';
    case 'Eco Explorer':
      return 'You\'re exploring sustainable habits and discovering new eco-friendly choices.';
    case 'Green Beginner':
    default:
      return 'You\'re just starting your eco journey! Every scan and challenge helps you grow greener.';
  }
}

/// Calculate points needed to reach next rank
int pointsToNextRank(int currentPoints) {
  final rank = rankForPoints(currentPoints);
  if (rank.maxPoints == null) return 0; // Already at max rank
  return rank.maxPoints! - currentPoints + 1;
}
