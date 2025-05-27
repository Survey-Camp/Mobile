import 'package:flutter/material.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/models/user_model.dart';

class CurrentProgressSection extends StatelessWidget {
  final AppUser user;
  final int monthlyGoal = 500; // Fixed monthly goal of 500 credits
  final int maxLevel = 10; // Maximum level

  const CurrentProgressSection({
    Key? key,
    required this.user,
  }) : super(key: key);

  double _calculateMonthlyProgress() {
    final currentPoints = user.totalPoints ?? 0;
    return (currentPoints / monthlyGoal).clamp(0.0, 1.0);
  }

  double _calculateLevelProgress() {
    final currentXP = user.xpPoints ?? 0;
    final currentLevel = _getCurrentLevel(currentXP);
    
    // Level thresholds
    final levelThresholds = [0, 200, 300, 500, 1000, 2000, 3500, 5500, 8000, 11000, 14500];
    
    if (currentLevel >= maxLevel) return 1.0;
    
    final currentLevelXP = levelThresholds[currentLevel];
    final nextLevelXP = levelThresholds[currentLevel + 1];
    final xpForNextLevel = nextLevelXP - currentLevelXP;
    final progress = (currentXP - currentLevelXP) / xpForNextLevel;
    
    return progress.clamp(0.0, 1.0);
  }

  int _getCurrentLevel(int points) {
    if (points >= 14500) return 10;
    if (points >= 11000) return 9;
    if (points >= 8000) return 8;
    if (points >= 5500) return 7;
    if (points >= 3500) return 6;
    if (points >= 2000) return 5;
    if (points >= 1000) return 4;
    if (points >= 500) return 3;
    if (points >= 300) return 2;
    if (points >= 200) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyProgress = _calculateMonthlyProgress();
    final levelProgress = _calculateLevelProgress();
    final currentLevel = _getCurrentLevel(user.xpPoints ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Current Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        _buildProgressCard(
          'Monthly Goal',
          '${user.totalPoints ?? 0}/$monthlyGoal',
          monthlyProgress,
          AppPalettes.primary,
          '${(monthlyProgress * 100).toInt()}%',
        ),
        _buildProgressCard(
          'Experience',
          'Level $currentLevel',
          levelProgress,
          Colors.purple,
          '${(levelProgress * 100).toInt()}%',
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    String title,
    String subtitle,
    double progress,
    Color color,
    String percentage,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}