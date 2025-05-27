class ShopData {
  final int xpPoints;
  final int totalPoints;
  final int level;
  final double progress;

  ShopData({
    required this.xpPoints,
    required this.totalPoints,
    this.level = 0,
    this.progress = 0,
  });

  factory ShopData.fromMap(Map<String, dynamic> map) {
    final xpPoints = map['xpPoints'] ?? 0;
    final level = (xpPoints / 100).floor();
    final progress = (xpPoints % 100) / 100;

    return ShopData(
      xpPoints: xpPoints,
      totalPoints: map['totalPoints'] ?? 0,
      level: level,
      progress: progress,
    );
  }
}