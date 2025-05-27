import 'package:flutter/material.dart';

class QuestionHeader extends StatefulWidget {
  final bool isFetchedQuestion;
  final TextEditingController questionController;
  final void Function() onDelete;
  final Function onUpdate;
  final dynamic questionData;

  const QuestionHeader({
    Key? key,
    required this.isFetchedQuestion,
    required this.questionController,
    required this.onDelete,
    required this.onUpdate,
    required this.questionData,
  }) : super(key: key);

  @override
  QuestionHeaderState createState() => QuestionHeaderState();
}

class QuestionHeaderState extends State<QuestionHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.questionController,
              enabled: !widget.isFetchedQuestion,
              maxLines: null, // Allows unlimited lines
              minLines: 1, // Starts with 1 line
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter your question',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
                isDense: true, // Makes the field more compact
                contentPadding: EdgeInsets.symmetric(vertical: 8), // Adjust padding
              ),
              onChanged: (value) {
                widget.questionData.question = value;
                widget.onUpdate(widget.questionData);
              },
            ),
          ),
          if (!widget.isFetchedQuestion)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onDelete,
              tooltip: 'Delete Question',
            ),
        ],
      ),
    );
  }
}
