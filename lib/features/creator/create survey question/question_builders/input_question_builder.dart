import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/questions.dart';

class InputQuestionBuilder implements QuestionContentBuilder {
  final QuestionData questionData;
  final bool isFetchedQuestion;

  InputQuestionBuilder({
    required this.questionData,
    required this.isFetchedQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    // Cleanup if needed
  }
}
