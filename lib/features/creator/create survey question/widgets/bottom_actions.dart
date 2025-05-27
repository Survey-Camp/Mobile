import 'package:flutter/material.dart';
import 'package:survey_camp/core/constants/constants.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/utils/responsive.dart';

class CreateQuestionsBottomActions extends StatelessWidget {
  final bool isLoading;
  final Responsive responsive;
  final VoidCallback onAddQuestion;
  final VoidCallback onSaveSurvey;

  const CreateQuestionsBottomActions({
    super.key,
    required this.isLoading,
    required this.responsive,
    required this.onAddQuestion,
    required this.onSaveSurvey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(responsive.screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: Constants.shadowBlur,
            offset: const Offset(0, Constants.shadowOffset),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAddButton(),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      backgroundColor: AppPalettes.primary,
      onPressed: onAddQuestion,
      child: const Icon(Icons.add, color: Colors.black),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalettes.primary,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.screenWidth * 0.08,
          vertical: responsive.screenHeight * 0.02,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.borderRadius),
        ),
      ),
      onPressed: isLoading ? null : onSaveSurvey,
      child: _buildSaveButtonChild(),
    );
  }

  Widget _buildSaveButtonChild() {
    if (isLoading) {
      return const SizedBox(
        width: Constants.circularProgressSize,
        height: Constants.circularProgressSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.black,
        ),
      );
    }
    return const Text('Save Survey');
  }
}
