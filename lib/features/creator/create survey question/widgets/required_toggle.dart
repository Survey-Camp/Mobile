import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';

class RequiredToggle extends StatefulWidget {
  final QuestionData questionData;
  final bool isFetchedQuestion;
  final Function(QuestionData) onUpdate;

  const RequiredToggle({
    Key? key,
    required this.questionData,
    required this.isFetchedQuestion,
    required this.onUpdate,
  }) : super(key: key);

  @override
  RequiredToggleState createState() => RequiredToggleState();
}

class RequiredToggleState extends State<RequiredToggle> {
  @override
  Widget build(BuildContext context) {
    return _buildRequiredToggle();
  }

  Widget _buildRequiredToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Required',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: widget.questionData.required,
            onChanged: widget.isFetchedQuestion
                ? null
                : (bool value) {
                    setState(() {
                      widget.questionData.required = value;
                      widget.onUpdate(widget.questionData);
                    });
                  },
          ),
        ],
      ),
    );
  }
}
