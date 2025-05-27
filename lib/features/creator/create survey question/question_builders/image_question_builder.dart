import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/questions.dart';

class ImageQuestionBuilder implements QuestionContentBuilder {
  final QuestionData questionData;
  final bool isFetchedQuestion;
  final Function(QuestionData) onUpdate;
  final List<TextEditingController> optionControllers;
  final ImagePicker _picker = ImagePicker();

  ImageQuestionBuilder({
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
          (index) => _buildImageOption(index),
        ),
        if (!isFetchedQuestion) _buildAddButton(),
      ],
    );
  }

  Widget _buildImageOption(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          Row(
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
          GestureDetector(
            onTap: isFetchedQuestion ? null : () => _pickImage(index),
            child: _buildImageContainer(index),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(int index) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: questionData.imageUrls?[index] != null
          ? _buildSelectedImage(index)
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildSelectedImage(int index) {
    final imageUrl = questionData.imageUrls?[index];

    if (imageUrl == null) {
      return _buildImagePlaceholder();
    }

    // Check if it's a network URL
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return _buildNetworkImage(imageUrl, index);
    }

    // Local file image handling
    try {
      final file = File(imageUrl);
      if (!file.existsSync()) {
        debugPrint('File does not exist: $imageUrl');
        return _buildImagePlaceholder();
      }

      return _buildLocalImage(file, index);
    } catch (e) {
      debugPrint('Error processing image: $e');
      return _buildErrorWidget(e);
    }
  }

  Widget _buildNetworkImage(String imageUrl, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Network image loading error: $error');
              return _buildErrorWidget(error);
            },
          ),
        ),
        if (!isFetchedQuestion)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _pickImage(index),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocalImage(File file, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Local image load error: $error');
              return _buildErrorWidget(error);
            },
          ),
        ),
        if (!isFetchedQuestion)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _pickImage(index),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.red),
            ),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Add Image',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionIndicator(int index) {
    return questionData.type == QuestionType.imageChoice
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
        label: const Text('Add Image Option'),
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
    questionData.imageUrls?.remove(index);
    optionControllers[index].dispose();
    optionControllers.removeAt(index);
    onUpdate(questionData);
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        questionData.imageUrls ??= {};
        questionData.imageUrls![index] = image.path;
        onUpdate(questionData);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    // Cleanup if needed
  }
}
