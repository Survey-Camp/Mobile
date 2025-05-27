class LevelSystem {
  static const List<int> levelXpRequirements = [
    0,     // Level 0 (unused)
    200,   // Level 1
    300,   // Level 2
    500,   // Level 3
    1000,  // Level 4
    2000,  // Level 5
    3500,  // Level 6
    5500,  // Level 7
    8000,  // Level 8
    11000, // Level 9
    14500, // Level 10
  ];

  static const Map<int, double> levelCreditRates = {
    3: 0.0003, // $0.0003 = 0.089 LKR
    4: 0.0004, // $0.0004 = 0.12 LKR
    5: 0.0005, // $0.0005 = 0.15 LKR
    6: 0.0006, // $0.0006 = 0.18 LKR
    7: 0.0007, // $0.0007 = 0.21 LKR
    8: 0.0008, // $0.0008 = 0.24 LKR
    9: 0.0009, // $0.0009 = 0.27 LKR
    10: 0.001, // $0.001 = 0.30 LKR
  };

  static const double usdToLkrRate = 297.0;
  static const int maxQuestionsPerSurvey = 15;
  static const int xpPerQuestion = 1;
  static const int creditsPerQuestion = 2;

  static int getCurrentLevel(int xpPoints) {
    for (int i = levelXpRequirements.length - 1; i >= 0; i--) {
      if (xpPoints >= levelXpRequirements[i]) {
        return i;
      }
    }
    return 0;
  }

  static double getProgress(int xpPoints) {
    int currentLevel = getCurrentLevel(xpPoints);
    if (currentLevel >= levelXpRequirements.length - 1) return 1.0;

    int currentLevelXp = levelXpRequirements[currentLevel];
    int nextLevelXp = levelXpRequirements[currentLevel + 1];
    int xpInCurrentLevel = xpPoints - currentLevelXp;
    int xpRequiredForNextLevel = nextLevelXp - currentLevelXp;

    return xpInCurrentLevel / xpRequiredForNextLevel;
  }

  static double getCreditValue(int credits, int level) {
    if (level < 3) return 0;
    double rate = levelCreditRates[level] ?? levelCreditRates[10]!;
    return credits * rate * usdToLkrRate;
  }

  static bool canEarnCredits(int level) {
    return level >= 3;
  }
}