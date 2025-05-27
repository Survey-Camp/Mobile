import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/questions.dart';

class TextQuestionBuilder implements QuestionContentBuilder {
  final QuestionData questionData;
  final bool isFetchedQuestion;
  final Function(QuestionData) onUpdate;
  final List<TextEditingController> optionControllers;

  TextQuestionBuilder({
    required this.questionData,
    required this.isFetchedQuestion,
    required this.onUpdate,
    required this.optionControllers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(
          questionData.options.length,
          (index) => _buildTextOption(index),
        ),
        if (!isFetchedQuestion) _buildAddButton(),
      ],
    );
  }

  Widget _buildTextOption(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Row(
        children: [
          _buildSelectionIndicator(index),
          Expanded(
            child: TextField(
              controller: optionControllers[index],
              enabled: !isFetchedQuestion,
              decoration: InputDecoration(
                hintText: 'Option ${index + 1}',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                questionData.options[index] = value;
                onUpdate(questionData);
              },
            ),
          ),
          if (!isFetchedQuestion)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _removeOption(index),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(int index) {
    return questionData.type == QuestionType.choice
        ? Radio<int>(
            value: index,
            groupValue: null,
            onChanged: (_) {},
          )
        : Checkbox(
            value: false,
            onChanged: (_) {},
          );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Option'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _addOption,
      ),
    );
  }

  void _addOption() {
    questionData.options.add('Option ${questionData.options.length + 1}');
    optionControllers.add(TextEditingController(
      text: 'Option ${questionData.options.length}',
    ));
    onUpdate(questionData);
  }

  void _removeOption(int index) {
    questionData.options.removeAt(index);
    optionControllers[index].dispose();
    optionControllers.removeAt(index);
    onUpdate(questionData);
  }

  @override
  void dispose() {
    // Cleanup if needed
  }
}
