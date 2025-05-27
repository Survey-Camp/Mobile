import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/questions.dart';

class RangeQuestionBuilder implements QuestionContentBuilder {
  final QuestionData questionData;
  final bool isFetchedQuestion;
  final Function(QuestionData) onUpdate;
  final ImagePicker _picker = ImagePicker();
  final Map<int, TextEditingController> _controllers = {};
  final List<String?> _originalImageUrls = [];

  RangeQuestionBuilder({
    required this.questionData,
    required this.isFetchedQuestion,
    required this.onUpdate,
  }) {
    _originalImageUrls
        .addAll(questionData.rangeOptions.map((option) => option.imageUrl));

    if (questionData.rangeOptions.any(
        (option) => option.imageUrl != null && option.imageUrl!.isNotEmpty)) {
      questionData.useImages = true;
    }
  }

  TextEditingController _getController(int index) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController(
        text: questionData.rangeOptions[index].text,
      );
    }
    return _controllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Rebuilding RangeQuestionBuilder');
    debugPrint('Total range options: ${questionData.rangeOptions.length}');
    debugPrint('Use Images: ${questionData.useImages}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRangeTypeSelector(),
        const SizedBox(height: 16),
        if (questionData.rangeOptions.isNotEmpty)
          ...List.generate(
            questionData.rangeOptions.length,
            (index) => _buildRangeOption(index, context),
          ),
        if (!isFetchedQuestion) _buildAddButton(),
      ],
    );
  }

  Widget _buildRangeTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeTypeSelectorButton(
            icon: Icons.text_fields,
            label: 'Text Only',
            isSelected: !questionData.useImages,
            onTap: () => _updateRangeType(useImages: false),
          ),
          _buildRangeTypeSelectorButton(
            icon: Icons.image,
            label: 'Images',
            isSelected: questionData.useImages,
            onTap: () => _updateRangeType(useImages: true),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeTypeSelectorButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isFetchedQuestion ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeOption(int index, BuildContext context) {
    final option = questionData.rangeOptions[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!questionData.useImages)
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _getController(index),
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  enabled: !isFetchedQuestion,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  onChanged: (value) {
                    option.text = value;
                    onUpdate(questionData);
                  },
                ),
              ),
            if (questionData.useImages) ...[
              _buildImageSelector(option, index, context),
              const SizedBox(height: 8),
              _buildRemoveImageButton(index),
            ],
            if (!isFetchedQuestion) _buildRemoveOptionButton(index),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector(
      RangeOption option, int index, BuildContext context) {
    debugPrint('Building image selector for index $index');
    debugPrint('Image URL: ${option.imageUrl}');

    if (option.imageUrl == null || option.imageUrl!.isEmpty) {
      return _buildEmptyImageSelector(index);
    }

    // Network image handling
    if (option.imageUrl!.startsWith('http') ||
        option.imageUrl!.startsWith('https')) {
      return GestureDetector(
        onTap: isFetchedQuestion ? null : () => _pickRangeImage(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            option.imageUrl!,
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
              debugPrint('Network image load error: $error');
              return _buildErrorWidget(error);
            },
          ),
        ),
      );
    }

    // Local file image handling
    try {
      final file = File(option.imageUrl!);
      if (!file.existsSync()) {
        debugPrint('File does not exist: ${option.imageUrl}');
        return _buildEmptyImageSelector(index);
      }

      return GestureDetector(
        onTap: isFetchedQuestion ? null : () => _pickRangeImage(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Local image load error: $error');
              return _buildErrorWidget(error);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error processing image: $e');
      return _buildErrorWidget(e);
    }
  }

  Widget _buildEmptyImageSelector(int index) {
    return GestureDetector(
      onTap: isFetchedQuestion ? null : () => _pickRangeImage(index),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate,
                  size: 32, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Add Image', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
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
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Range Option'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _addRangeOption,
      ),
    );
  }

  Widget _buildRemoveOptionButton(int index) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _removeRangeOption(index),
      ),
    );
  }

  Widget _buildRemoveImageButton(int index) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _removeRangeImage(index),
        child: const Text(
          'Remove Image',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void _updateRangeType({required bool useImages}) {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    questionData.useImages = useImages;

    // If switching to text mode, clear out image URLs but preserve originals
    if (!useImages) {
      for (int i = 0; i < questionData.rangeOptions.length; i++) {
        questionData.rangeOptions[i].text = 'Option ${i + 1}';
      }
    } else {
      // If switching to image mode, restore original images if available
      for (int i = 0; i < questionData.rangeOptions.length; i++) {
        if (i < _originalImageUrls.length && _originalImageUrls[i] != null) {
          questionData.rangeOptions[i].imageUrl = _originalImageUrls[i];
          questionData.rangeOptions[i].text = '';
        }
      }
    }

    // Ensure at least one option exists
    if (questionData.rangeOptions.isEmpty) {
      _addRangeOption();
    }

    onUpdate(questionData);
  }

  void _addRangeOption() {
    final index = questionData.rangeOptions.length;
    final option = RangeOption(
      value: index.toDouble(),
    );

    // Only set text if using text-only mode
    if (!questionData.useImages) {
      option.text = 'Option ${index + 1}';
    } else {
      // If in image mode, try to use original image if available
      if (index < _originalImageUrls.length &&
          _originalImageUrls[index] != null) {
        option.imageUrl = _originalImageUrls[index];
      }
    }

    questionData.rangeOptions.add(option);
    onUpdate(questionData);
  }

  void _removeRangeOption(int index) {
    if (index < 0 || index >= questionData.rangeOptions.length) {
      debugPrint('Invalid index for removal: $index');
      return;
    }

    _controllers[index]?.dispose();
    _controllers.remove(index);

    // Remove from original image URLs list as well
    if (index < _originalImageUrls.length) {
      _originalImageUrls.removeAt(index);
    }

    questionData.rangeOptions.removeAt(index);

    final remainingControllers =
        Map<int, TextEditingController>.from(_controllers);
    _controllers.clear();

    for (int i = 0; i < questionData.rangeOptions.length; i++) {
      if (remainingControllers.containsKey(i)) {
        _controllers[i] = remainingControllers[i]!;
      }
      questionData.rangeOptions[i].value = i.toDouble();
    }

    onUpdate(questionData);
  }

  void _removeRangeImage(int index) {
    if (index < 0 || index >= questionData.rangeOptions.length) {
      debugPrint('Invalid index for image removal: $index');
      return;
    }

    questionData.rangeOptions[index].imageUrl = null;
    onUpdate(questionData);
  }

  Future<void> _pickRangeImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        questionData.rangeOptions[index].imageUrl = image.path;
        questionData.rangeOptions[index].text = '';
        onUpdate(questionData);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
