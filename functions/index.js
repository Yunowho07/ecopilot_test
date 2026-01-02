// Firebase Cloud Functions Index
// Main entry point for all cloud functions

const dailyChallenges = require('./daily_challenges');
const dailyTips = require('./daily_tips');
const dynamicNotifications = require('./dynamic_notifications');
const streakNotifications = require('./streak_notifications');

// ============= Daily Challenges Functions =============
exports.generateDailyChallenges = dailyChallenges.generateDailyChallenges;
exports.manualGenerateChallenges = dailyChallenges.manualGenerateChallenges;
exports.updateUserStreak = dailyChallenges.updateUserStreak;

// ============= Daily Tips Functions =============
exports.generateDailyTips = dailyTips.generateDailyTips;
exports.manualGenerateTips = dailyTips.manualGenerateTips;

// ============= Dynamic Notifications Functions =============
exports.sendDynamicNotifications = dynamicNotifications.sendDynamicNotifications;

// ============= Streak Notifications Functions (NEW) =============
exports.checkStreaksAndSendReminders = streakNotifications.checkStreaksAndSendReminders;
exports.sendReEngagementNotifications = streakNotifications.sendReEngagementNotifications;
exports.sendMilestoneNotification = streakNotifications.sendMilestoneNotification;
exports.manualStreakCheck = streakNotifications.manualStreakCheck;
