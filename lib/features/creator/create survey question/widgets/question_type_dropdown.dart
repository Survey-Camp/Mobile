import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';

class QuestionTypeDropdown extends StatefulWidget {
  final QuestionData questionData;
  final bool isFetchedQuestion;
  final Function(QuestionData) onUpdate;

  const QuestionTypeDropdown({
    Key? key,
    required this.questionData,
    required this.isFetchedQuestion,
    required this.onUpdate,
  }) : super(key: key);

  @override
  QuestionTypeDropdownState createState() => QuestionTypeDropdownState();
}

class QuestionTypeDropdownState extends State<QuestionTypeDropdown> {
  bool get isImageType =>
      widget.questionData.type == QuestionType.multipleChoice;

  @override
  Widget build(BuildContext context) {
    return _buildQuestionTypeDropdown();
  }

  Widget _buildQuestionTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<QuestionType>(
          value: widget.questionData.type,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          onChanged: widget.isFetchedQuestion
              ? null
              : (QuestionType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      widget.questionData.type = newValue;
                      if (!isImageType) {
                        widget.questionData.imageUrls?.clear();
                      }
                      widget.onUpdate(widget.questionData);
                    });
                  }
                },
          items: QuestionType.values.map<DropdownMenuItem<QuestionType>>(
            (QuestionType type) {
              return DropdownMenuItem<QuestionType>(
                value: type,
                child: Text(
                  type
                      .toString()
                      .split('.')
                      .last
                      .replaceAll(RegExp(r'(?=[A-Z])'), ' '),
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
