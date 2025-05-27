import 'package:flutter/material.dart';
import 'package:survey_camp/core/utils/responsive.dart';

class SurveyButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isIconLeading;
  final Responsive responsive;
  final Color color;

  const SurveyButton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.responsive,
    required this.color,
    this.isIconLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 5,
        shadowColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.screenWidth * 0.06,
          vertical: responsive.screenHeight * 0.018,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isIconLeading
            ? [
                Icon(
                  icon,
                  color: Colors.black,
                  size: responsive.screenWidth * 0.05,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: responsive.screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: responsive.screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  icon,
                  color: Colors.black,
                  size: responsive.screenWidth * 0.05,
                ),
              ],
      ),
    );
  }
}

class PreviousButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onPressed;
  final Responsive responsive;
  final Color color;

  const PreviousButton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
    required this.responsive, 
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SurveyButton(
      isEnabled: isEnabled,
      onPressed: onPressed,
      label: 'Previous',
      icon: Icons.arrow_back_ios,
      responsive: responsive,
      color: color,
    );
  }
}

class NextButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onPressed;
  final bool isLastQuestion;
  final Responsive responsive;
  final Color color;

  const NextButton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
    required this.isLastQuestion,
    required this.responsive, 
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SurveyButton(
      isEnabled: isEnabled,
      onPressed: onPressed,
      label: isLastQuestion ? 'Finish' : 'Next',
      icon: isLastQuestion ? Icons.done : Icons.arrow_forward_ios,
      isIconLeading: false,
      responsive: responsive,
      color: color,
    );
  }
}
