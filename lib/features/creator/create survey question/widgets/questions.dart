import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/features/creator/create_survey_question/question_builders/image_question_builder.dart';
import 'package:survey_camp/features/creator/create_survey_question/question_builders/input_question_builder.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/question_header.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/question_type_dropdown.dart';
import 'package:survey_camp/features/creator/create_survey_question/question_builders/range_question_builder.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/required_toggle.dart';
import 'package:survey_camp/features/creator/create_survey_question/question_builders/text_question_builder.dart';

class QuestionCard extends StatefulWidget {
  final QuestionData questionData;
  final Function(QuestionData) onUpdate;
  final VoidCallback onDelete;
  final bool isFetchedQuestion;

  const QuestionCard({
    super.key,
    required this.questionData,
    required this.onUpdate,
    required this.onDelete,
    this.isFetchedQuestion = false,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

// Base Question Content Builder
abstract class QuestionContentBuilder {
  Widget build(BuildContext context);
  void dispose();
}

// QuestionCard State Implementation
class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController questionController;
  late List<TextEditingController> optionControllers;
  late QuestionContentBuilder contentBuilder;

  @override
  void initState() {
    super.initState();
    questionController =
        TextEditingController(text: widget.questionData.question);
    optionControllers = List.generate(
      widget.questionData.options.length,
      (index) =>
          TextEditingController(text: widget.questionData.options[index]),
    );
    _initializeContentBuilder();
  }

  @override
  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    contentBuilder.dispose();
    super.dispose();
  }

  void _initializeContentBuilder() {
    if (widget.questionData.type == QuestionType.imageChoice ||
        widget.questionData.type == QuestionType.imageMultipleChoice) {
      contentBuilder = ImageQuestionBuilder(
        questionData: widget.questionData,
        isFetchedQuestion: widget.isFetchedQuestion,
        onUpdate: widget.onUpdate,
        optionControllers: optionControllers,
      );
    } else if (widget.questionData.type == QuestionType.choice ||
        widget.questionData.type == QuestionType.multipleChoice ||
        widget.questionData.type == QuestionType.checkbox) {
      contentBuilder = TextQuestionBuilder(
        questionData: widget.questionData,
        isFetchedQuestion: widget.isFetchedQuestion,
        onUpdate: widget.onUpdate,
        optionControllers: optionControllers,
      );
    } else if (widget.questionData.type == QuestionType.textInput ||
        widget.questionData.type == QuestionType.paragraph ||
        widget.questionData.type == QuestionType.openEnded) {
      contentBuilder = InputQuestionBuilder(
        questionData: widget.questionData,
        isFetchedQuestion: widget.isFetchedQuestion,
      );
    } else if (widget.questionData.type == QuestionType.range) {
      contentBuilder = RangeQuestionBuilder(
        questionData: widget.questionData,
        isFetchedQuestion: widget.isFetchedQuestion,
        onUpdate: widget.onUpdate,
      );
    } else if (widget.questionData.type == QuestionType.slider ||
        widget.questionData.type == QuestionType.scale) {
      contentBuilder = RangeQuestionBuilder(
        questionData: widget.questionData,
        isFetchedQuestion: widget.isFetchedQuestion,
        onUpdate: widget.onUpdate,
      );
    } else {
      contentBuilder = TextQuestionBuilder(
        questionData: widget.questionData,
        isFetchedQuestion: widget.isFetchedQuestion,
        onUpdate: widget.onUpdate,
        optionControllers: optionControllers,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionHeader(
              isFetchedQuestion: widget.isFetchedQuestion,
              questionController: questionController,
              onDelete: widget.onDelete,
              onUpdate: widget.onUpdate,
              questionData: widget.questionData,
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuestionTypeDropdown(
                    questionData: widget.questionData,
                    isFetchedQuestion: widget.isFetchedQuestion,
                    onUpdate: (data) {
                      widget.onUpdate(data);
                      _initializeContentBuilder();
                    },
                  ),
                  const SizedBox(height: 24),
                  contentBuilder.build(context),
                  const SizedBox(height: 16),
                  RequiredToggle(
                    questionData: widget.questionData,
                    isFetchedQuestion: widget.isFetchedQuestion,
                    onUpdate: widget.onUpdate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
