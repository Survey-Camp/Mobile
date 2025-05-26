import 'package:flutter/widgets.dart';

class Responsive {
  final BuildContext context;
  Responsive(this.context);

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // Example for scaling sizes
  double get proportionalWidth => screenWidth * 0.05;
  double get proportionalHeight => screenHeight * 0.03;

  // You can also scale font size based on screen width
  double get scaledFontSize => screenWidth * 0.05;
}
