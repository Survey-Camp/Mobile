import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/core/services/generate_survey.dart';
import 'package:survey_camp/core/services/update_question.dart';
import 'package:survey_camp/features/creator/create_survey_question/create_survey_with_ai.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/shared/widgets/top_bar.dart';

class GenerateQuestionScreen extends StatefulWidget {
  final String title;
  final String description;
  final String? category;
  final String? surveyId;
  const GenerateQuestionScreen({
    super.key,
    this.category,
    required this.title,
    required this.description,
    this.surveyId,
  });

  @override
  State<GenerateQuestionScreen> createState() => _GenerateQuestionScreenState();
}

class _GenerateQuestionScreenState extends State<GenerateQuestionScreen> {
  final _surveyGoalController = TextEditingController();
  final _customTopicController = TextEditingController();
  List<String> selectedTopics = [];
  List<String> customTopics = [];
  bool _isLoading = false;
  String? _errorMessage;
  final SurveyGeneratorService _surveyService = SurveyGeneratorService();

  final List<String> availableTopics = [
    'Customer Satisfaction',
    'Product Feedback',
    'Market Research',
    'Employee Engagement',
    'Event Feedback',
    'User Experience',
    'Brand Awareness',
  ];

  void _addCustomTopic() {
    if (_customTopicController.text.trim().isNotEmpty) {
      setState(() {
        customTopics.add(_customTopicController.text.trim());
        selectedTopics.add(_customTopicController.text.trim());
        _customTopicController.clear();
      });
    }
  }

  Future<void> _generateSurvey() async {
    // Validate inputs
    if (_surveyGoalController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please define your survey goal';
      });
      return;
    }

    if (selectedTopics.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one topic';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

      try {
    // Create a detailed prompt with all selected topics and survey goal
    final String prompt = '''
Create exactly 15 survey questions for ${_surveyGoalController.text.trim()} 
focusing on the following topics: ${selectedTopics.join(', ')}.
Include a diverse mix of question types including multiple choice, Yes/No, Rating Scales (1-5), 
and open-ended questions. For multiple choice questions, provide 3-5 relevant options.
Title: ${widget.title}
Description: ${widget.description}

Format each question as:
{
  "text": "Question text here",
  "type": "multiple choice OR rating scale OR open-ended",
  "options": ["Option 1", "Option 2", "Option 3"]
}
    ''';

      // Call the survey generation service
      final List<Map<String, dynamic>> surveyQuestionsResponse = 
          await _surveyService.generateSurvey(prompt);

      if (surveyQuestionsResponse.isEmpty) {
        throw Exception('No questions were generated. Please try again.');
      }

      // Debug log to see what's being returned
      print('API Response: $surveyQuestionsResponse');

      // Process the response into QuestionData objects
      final List<QuestionData> generatedQuestions = [];

      // Inspect the first item for troubleshooting
      if (surveyQuestionsResponse.isNotEmpty) {
        print('First question: ${surveyQuestionsResponse[0]}');
      }

      // Check if there's a warning or error message in the response
      if (surveyQuestionsResponse.length == 1 && 
          (surveyQuestionsResponse[0].containsKey('warning') || 
           surveyQuestionsResponse[0].containsKey('error'))) {
        
        final message = surveyQuestionsResponse[0]['warning'] ?? 
                        surveyQuestionsResponse[0]['error'] ??
                        'Unknown error in API response';
        
        throw Exception('API Error: $message');
      }

      for (var questionJson in surveyQuestionsResponse) {
        // Extract question information with more robust fallback handling
        String questionType = '';
        String questionText = '';
        
        // Try multiple possible field names for question text
        if (questionJson.containsKey('text')) {
          questionText = questionJson['text'] ?? '';
        } else if (questionJson.containsKey('question')) {
          questionText = questionJson['question'] ?? '';
        } else if (questionJson.containsKey('question_text')) {
          questionText = questionJson['question_text'] ?? '';
        }
        
        // If we still don't have text, look for it in any string field
        if (questionText.isEmpty) {
          for (var key in questionJson.keys) {
            if (questionJson[key] is String && 
                (questionJson[key] as String).contains('?')) {
              questionText = questionJson[key];
              break;
            }
          }
        }
        
        // Try multiple possible field names for question type
        if (questionJson.containsKey('type')) {
          questionType = questionJson['type'] ?? '';
        } else if (questionJson.containsKey('question_type')) {
          questionType = questionJson['question_type'] ?? '';
        }
        
        // If the questionText is the whole JSON as a string (possible API error case)
        if (questionText.isEmpty && questionJson.toString().contains('?')) {
          try {
            // Try to extract a question from the whole JSON string
            final String jsonStr = questionJson.toString();
            final RegExp questionRegex = RegExp(r'([^.?!]+\?)', multiLine: true);
            final Match? match = questionRegex.firstMatch(jsonStr);
            if (match != null) {
              questionText = match.group(1)?.trim() ?? '';
            }
          } catch (e) {
            print('Error extracting question from string: $e');
          }
        }
        
        // Skip if we still couldn't find a question
        if (questionText.isEmpty) {
          print('Skipping question with empty text: $questionJson');
          continue;
        }

        print('Processing question: "$questionText" of type: "$questionType"');

        // Map API response question types to app question types
        QuestionType type;
        List<String> options = [];

        // Normalize the question type to lowercase for consistent comparison
        String normalizedType = questionType.toLowerCase();

        // Attempt to identify the question type
        if (normalizedType.contains('rating') || normalizedType.contains('scale')) {
          type = QuestionType.scale;
          options = ["1-5"];
        } else if (normalizedType.contains('yes') && normalizedType.contains('no')) {
          type = QuestionType.multipleChoice;
          options = ['Yes', 'No'];
        } else if (normalizedType.contains('multiple') || normalizedType.contains('mcq')) {
          type = QuestionType.multipleChoice;
          
          // Extract options with more robust fallback
          var rawOptions = 
              questionJson['options'] ?? 
              questionJson['choices'] ?? 
              questionJson['answer_choices'] ??
              questionJson['answers'];
              
          if (rawOptions is List) {
            // Convert all list items to strings
            options = rawOptions.map((opt) => opt.toString()).toList();
          } else if (rawOptions is String) {
            // Handle comma-separated options
            options = rawOptions.split(',').map((e) => e.trim()).toList();
          } else {
            // Default options
            options = ['Option 1', 'Option 2', 'Option 3'];
          }
        } else if (normalizedType.contains('text') || normalizedType.contains('open')) {
          type = QuestionType.textInput;
        } else {
          // If type not specified, guess based on the question content
          if (questionText.toLowerCase().contains("rate") || 
              questionText.toLowerCase().contains("scale") ||
              questionText.toLowerCase().contains("from 1 to 5")) {
            type = QuestionType.scale;
            options = ["1-5"];
          } else if (questionText.endsWith("?") && 
                    (questionText.toLowerCase().contains("what") || 
                    questionText.toLowerCase().contains("how") || 
                    questionText.toLowerCase().contains("describe") ||
                    questionText.toLowerCase().contains("explain"))) {
            type = QuestionType.textInput;
          } else {
            // Default to multiple choice
            type = QuestionType.multipleChoice;
            
            // Try to extract options from various fields in the response
            var extractedOptions = 
                questionJson['options'] ?? 
                questionJson['choices'] ?? 
                questionJson['answer_choices'] ??
                questionJson['answers'];
            
            if (extractedOptions is List) {
              options = extractedOptions.map((opt) => opt.toString()).toList();
            } else {
              // Create meaningful default options based on question type
              if (questionText.toLowerCase().contains("satisfy") || 
                  questionText.toLowerCase().contains("agree")) {
                options = ['Strongly Disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly Agree'];
              } else if (questionText.toLowerCase().contains("likely")) {
                options = ['Very Unlikely', 'Unlikely', 'Neutral', 'Likely', 'Very Likely'];
              } else if (questionText.toLowerCase().contains("frequency") || 
                        questionText.toLowerCase().contains("often")) {
                options = ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'];
              } else {
                // Generic default options
                options = ['Option 1', 'Option 2', 'Option 3'];
              }
            }
          }
        }

        print('Question type determined: $type with options: $options');

        // Create and add the question
        generatedQuestions.add(
          QuestionData(
            question: questionText,
            type: type,
            options: options,
            required: true,
          ),
        );
      }

      // Ensure we have at least one question
      if (generatedQuestions.isEmpty) {
        print('No valid questions were generated from the API response');
        
        // Add a fallback question if nothing was successfully generated
        generatedQuestions.add(
          QuestionData(
            question: "How would you rate your overall experience?",
            type: QuestionType.scale,
            options: ["1-5"],
            required: true,
          ),
        );
        
        generatedQuestions.add(
          QuestionData(
            question: "What aspects could be improved?",
            type: QuestionType.textInput,
            options: [],
            required: true,
          ),
        );
      }

      print('Successfully generated ${generatedQuestions.length} questions');

      // Navigate to the survey creation screen with generated questions
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateSurveyAIScreen(
              title: widget.title,
              description: widget.description,
              category: widget.category,
              surveyId: widget.surveyId,
              initialQuestions: generatedQuestions,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _generateSurvey: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.screenWidth * 0.05,
              vertical: responsive.screenHeight * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomTopBar(),
                const SizedBox(height: 32),

                // Title Section
                Text(
                  'Generate Survey',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Define your survey goals and topics to generate targeted questions',
                  style: TextStyle(
                    fontSize: descriptionFontSize,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // Survey Goal Input
                _buildInputSection(
                  'Survey Goal',
                  'What do you want to achieve with this survey?',
                  _surveyGoalController,
                ),
                const SizedBox(height: 32),

                // Topics Section
                Text(
                  'Select Topics',
                  style: TextStyle(
                    fontSize: responsive.screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from suggestions or add your own',
                  style: TextStyle(
                    fontSize: responsive.screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Custom Topic Input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customTopicController,
                        decoration: InputDecoration(
                          hintText: 'Add custom topic',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onFieldSubmitted: (_) => _addCustomTopic(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addCustomTopic,
                      icon: const Icon(Icons.add_circle),
                      color: AppPalettes.primary,
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Topics Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...availableTopics.map((topic) => _buildTopicChip(topic)),
                    ...customTopics
                        .map((topic) => _buildTopicChip(topic, isCustom: true)),
                  ],
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateSurvey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalettes.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Generating...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Generate Questions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),

                // Advanced info message
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Pro Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For best results, be specific about your survey goal and select relevant topics. Our AI will generate a balanced mix of question types tailored to your needs.',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChip(String topic, {bool isCustom = false}) {
    final isSelected = selectedTopics.contains(topic);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(topic),
          if (isCustom) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: isSelected ? Colors.blue[800] : Colors.grey[600],
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            selectedTopics.add(topic);
          } else {
            selectedTopics.remove(topic);
            if (isCustom) {
              customTopics.remove(topic);
            }
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[800] : Colors.black87,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    );
  }

  Widget _buildInputSection(
    String title,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          maxLines: 3,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _surveyGoalController.dispose();
    _customTopicController.dispose();
    super.dispose();
  }
}
