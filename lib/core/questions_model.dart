
//calss SurveyQuestion
class SurveyQuestion {
  final String question;
  final List<String> answers;
  final int? correctAnswerIndex;
  final QuestionType questionType;
  final double? minValue;
  final double? maxValue;
  final double? initialValue;
  final Map<int, String>? imageUrls;
  final Map<String, dynamic>? sentiment;


  SurveyQuestion({
    required this.question,
    this.answers = const [],
    this.correctAnswerIndex,
    this.questionType = QuestionType.multipleChoice,
    this.minValue,
    this.maxValue,
    this.initialValue,
    this.imageUrls,
    this.sentiment,
  });
}

enum QuestionType {
  textInput,
  paragraph,
  multipleChoice,
  checkbox,
  imageChoice,
  imageMultipleChoice,
  range,
  choice,
  dropdown,
  imageCheckbox,
  scale,
  slider,
  ratingScale,
  openEnded
}

class RangeOption {
  String? text;
  String? iconPath;
  String? imageUrl;
  double value;

  RangeOption({
    this.text,
    this.iconPath,
    this.imageUrl,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'iconPath': iconPath,
        'imageUrl': imageUrl,
        'value': value,
      };

  factory RangeOption.fromJson(Map<String, dynamic> json) => RangeOption(
        text: json['text'],
        iconPath: json['iconPath'],
        imageUrl: json['imageUrl'],
        value: json['value'],
      );
}

class QuestionData {
  String question;
  QuestionType type;
  List<String> options;
  Map<int, String>? imageUrls;
  bool required;
  List<RangeOption> rangeOptions;
  bool useIcons;
  bool useImages;
  final int? minValue;
  final int? maxValue;
  final String? minLabel;
  final String? maxLabel;

  QuestionData({
    required this.question,
    required this.type,
    List<String>? options,
    this.imageUrls,
    this.required = false,
    List<RangeOption>? rangeOptions,
    this.useIcons = false,
    this.useImages = false,
    this.minValue,
    this.maxValue,
    this.minLabel,
    this.maxLabel,
  })  : options = options ?? [],
        rangeOptions = rangeOptions ?? [] {
    // Ensure imageUrls is initialized as an empty map if null
    imageUrls ??= {};
  }

  @override
  String toString() {
    return 'QuestionData(question: "$question", type: $type, options: $options, required: $required, useIcons: $useIcons, useImages: $useImages)';
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'type': type.toString(),
      'options': options,
      // Convert imageUrls to a map of string keys
      'imageUrls':
          imageUrls?.map((key, value) => MapEntry(key.toString(), value)),
      'required': required,
      'rangeOptions': rangeOptions.map((o) => o.toJson()).toList(),
      'useIcons': useIcons,
      'useImages': useImages,
    };
  }

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      question: json['question'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(json['options'] ?? []),
      // Safely convert image URLs
      imageUrls: json['imageUrls'] != null
          ? Map.fromEntries(
              (json['imageUrls'] as Map).entries.map(
                    (entry) =>
                        MapEntry(int.parse(entry.key.toString()), entry.value),
                  ),
            )
          : null,
      required: json['required'] ?? false,
      rangeOptions: (json['rangeOptions'] as List?)
              ?.map((o) => RangeOption.fromJson(o))
              .toList() ??
          [],
      useIcons: json['useIcons'] ?? false,
      useImages: json['useImages'] ?? false,
    );
  }
}
