import 'package:flutter/material.dart';
import 'package:survey_camp/core/constants/constants.dart';
import 'package:survey_camp/core/utils/responsive.dart';

class CreateQuestionsScreenHeader extends StatelessWidget {
  final String title;
  final String description;
  final Responsive responsive;
  final double padding;
  final double iconSize;

  const CreateQuestionsScreenHeader(
      {super.key,
      required this.title,
      required this.description,
      required this.responsive,
      required this.padding,
      required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.screenWidth * 0.05,
        vertical: responsive.screenHeight * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: iconSize,
                  color: Colors.black87,
                )),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.screenWidth * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Constants.headerVerticalPadding),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Constants.verticalSpacing),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.screenWidth * 0.04,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
