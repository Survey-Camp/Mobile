import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/shared/widgets/custom_appbar_back.dart';
import 'package:survey_camp/features/survey_page/widgets/finish_dialog.dart';
import 'package:survey_camp/features/survey_page/widgets/survey_buttons.dart';
import 'package:survey_camp/core/repositories/survey_repository.dart';
import 'package:survey_camp/shared/theme/category_colors.dart';
import 'package:survey_camp/core/services/ml_api_services.dart';
import 'dart:convert';

class SurveyPage extends ConsumerStatefulWidget {
  final String surveyId;
  final String categoryName;

  const SurveyPage({
    Key? key,
    required this.surveyId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends ConsumerState<SurveyPage>
    with SingleTickerProviderStateMixin {
  late final Responsive responsive;
  int _currentQuestionIndex = 0;
  List<int> _selectedAnswerIndices = [];
  List<dynamic> _userAnswers = [];
  Map<int, TextEditingController> _textControllers = {};
  Map<int, double> _sliderValues = {};

  final ScrollController _scrollController = ScrollController();
  int _scrollCount = 0;
  Map<int, int> _questionScrolls = {};

  DateTime? _surveyStartTime;
  Map<int, DateTime> _questionStartTimes = {};
  Map<int, Duration> _questionDurations = {};
  Map<int, int> _questionClicks = {};

  int _calculateQuestionClicks() {
    return _questionClicks.values.fold(0, (sum, clicks) => sum + clicks);
  }

  double _calculateTotalTime() {
    return _questionDurations.values.fold(
      0.0,
      (sum, duration) => sum + duration.inSeconds,
    );
  }

  Offset? _dragStartPosition;
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  List<QuestionData> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  final SurveyRepository _surveyRepository = SurveyRepository();
  final MLApiService _mlService = MLApiService();

  String _getCategoryId() {
    return widget.categoryName.toLowerCase().replaceAll('/', '');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    responsive = Responsive(context);
    _surveyStartTime = DateTime.now();
    _questionStartTimes[0] = DateTime.now();
    _initializeQuestions();
    _initializeAnimationController();
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_animationController);
  }

  void _incrementQuestionInteractionClicks(int questionIndex) {
    setState(() {
      _questionClicks[questionIndex] = (_questionClicks[questionIndex] ?? 0) + 1;
    });
  }

  Future<void> _initializeQuestions() async {
    try {
      final questions = await _surveyRepository.loadQuestions(widget.surveyId);
      setState(() {
        _questions = questions;
        _userAnswers = List.filled(questions.length, null);
        _selectedAnswerIndices = List.filled(questions.length, -1);

        for (int i = 0; i < questions.length; i++) {
          if (questions[i].type == QuestionType.textInput ||
              questions[i].type == QuestionType.paragraph ||
              questions[i].type == QuestionType.openEnded) {
            _textControllers[i] = TextEditingController();
          }
          if (questions[i].type == QuestionType.scale ||
              questions[i].type == QuestionType.slider ||
              questions[i].type == QuestionType.ratingScale) {
            _sliderValues[i] = 70.0;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load survey questions';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textControllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollCount++;
      _questionScrolls[_currentQuestionIndex] =
          (_questionScrolls[_currentQuestionIndex] ?? 0) + 1;
    });
  }

  void _incrementQuestionClicks(int questionIndex) {
    setState(() {
      _questionClicks[questionIndex] = (_questionClicks[questionIndex] ?? 0) + 1;
      print(
          'Question ${questionIndex + 1} clicks: ${_questionClicks[questionIndex]}');
    });
  }

  int _calculateTotalClicks() {
    final interactionClicks =
        _questionClicks.values.fold(0, (sum, clicks) => sum + clicks);
    final scrollInteractions =
        _questionScrolls.values.fold(0, (sum, scrolls) => sum + scrolls);
    final totalInteractions = interactionClicks + scrollInteractions;

    print('''
Interaction Metrics:
- Total Clicks: $interactionClicks
- Total Scrolls: $scrollInteractions
- Combined Interactions: $totalInteractions
- Per Question Clicks: ${_questionClicks.toString()}
- Per Question Scrolls: ${_questionScrolls.toString()}
    ''');

    return totalInteractions;
  }

  void _moveToNextQuestion() async {
    if (_canProceedToNextQuestion()) {
      _recordQuestionTime();
      bool isLastQuestion = _currentQuestionIndex >= _questions.length - 1;

      if (!isLastQuestion) {
        _animateQuestionTransition(1);
        _questionStartTimes[_currentQuestionIndex + 1] = DateTime.now();
      } else {
        _showFinishDialog();
      }
    }
  }

  void _moveToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _recordQuestionTime();
      _animateQuestionTransition(-1);
      _questionStartTimes[_currentQuestionIndex - 1] = DateTime.now();
    }
  }

  void _recordQuestionTime() {
    final questionStartTime = _questionStartTimes[_currentQuestionIndex];
    if (questionStartTime != null) {
      final timeSpent = DateTime.now().difference(questionStartTime);
      _questionDurations[_currentQuestionIndex] = timeSpent;
    }
  }

  void _animateQuestionTransition(int direction) {
    _animation = Tween<Offset>(
      begin: Offset(direction.toDouble(), 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();

    setState(() {
      _currentQuestionIndex += direction;
    });

    _animationController.forward();
  }

  bool _canProceedToNextQuestion() {
    if (_isLoading || _currentQuestionIndex >= _questions.length) return false;

    QuestionData currentQuestion = _questions[_currentQuestionIndex];
    bool canProceed = false;

    switch (currentQuestion.type) {
      case QuestionType.multipleChoice:
      case QuestionType.choice:
      case QuestionType.imageChoice:
      case QuestionType.checkbox:
      case QuestionType.imageCheckbox:
      case QuestionType.imageMultipleChoice:
        canProceed = _selectedAnswerIndices[_currentQuestionIndex] != -1;
        break;
      case QuestionType.scale:
      case QuestionType.slider:
      case QuestionType.ratingScale:
        canProceed = true;
        _userAnswers[_currentQuestionIndex] =
            _sliderValues[_currentQuestionIndex];
        break;
      case QuestionType.textInput:
      case QuestionType.paragraph:
      case QuestionType.openEnded:
        canProceed = _textControllers[_currentQuestionIndex]!.text.isNotEmpty;
        if (canProceed) {
          _userAnswers[_currentQuestionIndex] =
              _textControllers[_currentQuestionIndex]!.text;
        }
        break;
      case QuestionType.range:
        canProceed = _selectedAnswerIndices[_currentQuestionIndex] != -1;
        break;
      default:
        canProceed = true;
        break;
    }

    return canProceed;
  }

  bool _isNextButtonEnabled() {
    if (_isLoading || _currentQuestionIndex >= _questions.length) return false;

    QuestionData currentQuestion = _questions[_currentQuestionIndex];

    switch (currentQuestion.type) {
      case QuestionType.choice:
      case QuestionType.multipleChoice:
      case QuestionType.imageChoice:
      case QuestionType.range:
        return _selectedAnswerIndices[_currentQuestionIndex] != -1;
      case QuestionType.scale:
      case QuestionType.slider:
      case QuestionType.ratingScale:
        return true;
      case QuestionType.textInput:
      case QuestionType.paragraph:
      case QuestionType.openEnded:
        return _textControllers[_currentQuestionIndex]!.text.isNotEmpty;
      default:
        return false;
    }
  }

  void _showFinishDialog() async {
    _recordQuestionTime();

    final surveyEndTime = DateTime.now();
    final totalDuration = surveyEndTime.difference(_surveyStartTime!);
    final totalTime = totalDuration.inSeconds.toDouble();
    final totalInteractions = _calculateTotalClicks();

    // Analyze sentiment for all text-based answers before showing dialog
    for (int i = 0; i < _questions.length; i++) {
      QuestionData question = _questions[i];
      dynamic answer = _userAnswers[i];

      if ((question.type == QuestionType.textInput ||
           question.type == QuestionType.paragraph ||
           question.type == QuestionType.openEnded) &&
          answer != null) {
        try {
          final sentimentResult = await _mlService.predictSentiment(answer.toString());
          _userAnswers[i] = {
            'text': answer,
            'sentiment': sentimentResult,
            'questionType': question.type.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          };
        } catch (e) {
          print('Error analyzing sentiment for question ${i + 1}: $e');
          _userAnswers[i] = {
            'text': answer,
            'sentiment': null,
            'questionType': question.type.toString(),
            'timestamp': DateTime.now().toIso8601String(),
            'error': e.toString()
          };
        }
      }
    }

    final Map<String, dynamic> timeMetrics = {
      'surveyStartTime': _surveyStartTime!.toIso8601String(),
      'surveyEndTime': surveyEndTime.toIso8601String(),
      'totalDuration': totalDuration.inSeconds,
      'questionDurations': _questionDurations
          .map((key, value) => MapEntry(key.toString(), value.inSeconds)),
      'totalInteractions': totalInteractions,
      'questionClicks': _questionClicks,
      'questionScrolls': _questionScrolls,
      'totalScrolls': _scrollCount,
    };

    List<SurveyQuestion> surveyQuestions = _questions.map((questionData) {
      return SurveyQuestion(
        question: questionData.question,
        questionType: questionData.type,
        answers: questionData.options,
        correctAnswerIndex: null,
      );
    }).toList();

    // Get quality prediction
    try {
      final qualityResult = await _mlService.predictResponseQuality(
        scrollingBehavior: totalInteractions,
        idleTime: 0,
        typingPatterns: 1,
        totalTime: totalTime,
      );
      timeMetrics['qualityPrediction'] = qualityResult['prediction'] ?? -1;
    } catch (e) {
      print('ML API Error: $e');
      timeMetrics['qualityPrediction'] = -1;
    }

    // Show dialog after all processing is complete
    if (mounted) {
      FinishDialog.showFinishDialog(
        context,
        surveyQuestions,
        _userAnswers,
        widget.surveyId,
        ref,
        timeMetrics,
        isPoorQuality: false,
      );
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartPosition = details.globalPosition;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_dragStartPosition == null) return;

    final dragDistance = details.primaryVelocity ?? 0;

    if (dragDistance < -500) {
      _moveToNextQuestion();
    } else if (dragDistance > 500) {
      _moveToPreviousQuestion();
    }
  }

  Widget _buildQuestionContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(child: Text('No questions found'));
    }

    QuestionData currentQuestion = _questions[_currentQuestionIndex];

    switch (currentQuestion.type) {
      case QuestionType.multipleChoice:
      case QuestionType.choice:
      case QuestionType.checkbox:
        return _buildChoiceQuestionContent(currentQuestion);
      case QuestionType.imageChoice:
      // Correct or remove the case statement
      // case QuestionType.someValidType:
      case QuestionType.imageMultipleChoice:
      case QuestionType.imageCheckbox:
        return _buildImageChoiceContent(currentQuestion);
      case QuestionType.scale:
      case QuestionType.slider:
      case QuestionType.ratingScale:
        return _buildScaleQuestionContent(currentQuestion);
      case QuestionType.textInput:
      case QuestionType.paragraph:
      case QuestionType.openEnded:
        return _buildTextInputQuestionContent(currentQuestion);
      case QuestionType.range:
        return _buildRangeQuestionContent(currentQuestion);
      default:
        return Text('Unsupported question type');
    }

    // Default return in case no condition is met
    return Center(child: Text('Unexpected error occurred'));
  }

  Widget _buildChoiceQuestionContent(QuestionData currentQuestion) {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: currentQuestion.options.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: responsive.screenHeight * 0.02),
            child: ListTile(
              onTap: () {
                _incrementQuestionInteractionClicks(_currentQuestionIndex);
                setState(() {
                  _selectedAnswerIndices[_currentQuestionIndex] = index;
                  _userAnswers[_currentQuestionIndex] = index;
                });
              },
              leading: Radio<int>(
                value: index,
                groupValue: _selectedAnswerIndices[_currentQuestionIndex],
                onChanged: (value) {
                  setState(() {
                    _selectedAnswerIndices[_currentQuestionIndex] = value!;
                    _userAnswers[_currentQuestionIndex] = value;
                  });
                },
              ),
              title: Text(
                currentQuestion.options[index],
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              tileColor: _selectedAnswerIndices[_currentQuestionIndex] == index
                  ? const Color(0xFFFFC49F).withOpacity(0.1)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: _selectedAnswerIndices[_currentQuestionIndex] == index
                      ? Colors.deepOrange
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageChoiceContent(QuestionData currentQuestion) {
    return Expanded(
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: responsive.screenWidth * 0.03,
          mainAxisSpacing: responsive.screenWidth * 0.03,
          childAspectRatio: 1,
        ),
        itemCount: currentQuestion.options.length,
        itemBuilder: (context, index) {
          bool isSelected =
              _selectedAnswerIndices[_currentQuestionIndex] == index;
          String? imageUrl = currentQuestion.imageUrls?[index];

          return GestureDetector(
            onTap: () {
              _incrementQuestionClicks(_currentQuestionIndex);
              setState(() {
                _selectedAnswerIndices[_currentQuestionIndex] = index;
                _userAnswers[_currentQuestionIndex] = index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Colors.deepOrange
                      : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? const Color(0xFFFFC49F).withOpacity(0.1)
                    : Colors.white,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: responsive.screenWidth * 0.3,
                          height: responsive.screenWidth * 0.3,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.error, color: Colors.red);
                          },
                        )
                      : Icon(Icons.image, size: responsive.screenWidth * 0.3),
                  SizedBox(height: 8),
                  Text(
                    currentQuestion.options[index],
                    style: TextStyle(
                      color: isSelected ? Colors.deepOrange : Colors.black54,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScaleQuestionContent(QuestionData currentQuestion) {
    return Expanded(
      child: Column(
        children: [
          Slider(
            value: _sliderValues[_currentQuestionIndex] ?? 70.0,
            min: 0,
            max: 100,
            divisions: 20,
            label: (_sliderValues[_currentQuestionIndex] ?? 70.0)
                .round()
                .toString(),
            onChanged: (double value) {
              setState(() {
                _sliderValues[_currentQuestionIndex] = value;
                _userAnswers[_currentQuestionIndex] = value;
              });
            },
          ),
          Text(
            'Selected Value: ${(_sliderValues[_currentQuestionIndex] ?? 70.0).round()}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _buildTextInputQuestionContent(QuestionData currentQuestion) {
    return Expanded(
      child: TextField(
        controller: _textControllers[_currentQuestionIndex],
        maxLines: 5,
        decoration: InputDecoration(
          hintText: currentQuestion.type == QuestionType.paragraph
              ? 'Enter your detailed thoughts...'
              : 'Enter your answer...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          _userAnswers[_currentQuestionIndex] = value;
        },
      ),
    );
  }

  Widget _buildRangeQuestionContent(QuestionData currentQuestion) {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: currentQuestion.rangeOptions.length,
        itemBuilder: (context, index) {
          final option = currentQuestion.rangeOptions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                if (option.imageUrl != null && option.imageUrl!.isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    margin: EdgeInsets.only(right: 12),
                    child: Image.network(
                      option.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.file(
                          File(option.imageUrl!),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: RadioListTile<int>(
                    title: Text(option.text ?? ''),
                    value: index,
                    groupValue: _selectedAnswerIndices[_currentQuestionIndex],
                    onChanged: (value) {
                      setState(() {
                        _selectedAnswerIndices[_currentQuestionIndex] = value!;
                        _userAnswers[_currentQuestionIndex] = {
                          'index': value,
                          'text': currentQuestion.rangeOptions[value].text,
                          'imageUrl':
                              currentQuestion.rangeOptions[value].imageUrl
                        };
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final categoryId = _getCategoryId();
    double padding = responsive.screenWidth * 0.05;

    return Scaffold(
      backgroundColor: CategoryColors.getLightColor(categoryId),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: responsive.screenHeight * 0.03,
          ),
          child: GestureDetector(
            onHorizontalDragStart: _handleHorizontalDragStart,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SlideTransition(
                    position: _animation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomAppBarBack(
                          title: 'Survey Page',
                          color: CategoryColors.getPrimaryColor(categoryId),
                        ),
                        SizedBox(height: padding),
                        Container(
                          padding: EdgeInsets.all(padding * 0.8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: CategoryColors.getPrimaryColor(categoryId)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${_currentQuestionIndex + 1}. ${_questions[_currentQuestionIndex].question}',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: CategoryColors.getDarkColor(categoryId),
                            ),
                          ),
                        ),
                        SizedBox(height: padding),
                        _buildQuestionContent(),
                        SizedBox(height: padding),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PreviousButton(
                              isEnabled: _currentQuestionIndex > 0,
                              onPressed: _moveToPreviousQuestion,
                              responsive: responsive,
                              color: CategoryColors.getPrimaryColor(categoryId),
                            ),
                            NextButton(
                              isEnabled: _isNextButtonEnabled(),
                              onPressed: _moveToNextQuestion,
                              isLastQuestion: _currentQuestionIndex ==
                                  _questions.length - 1,
                              responsive: responsive,
                              color: CategoryColors.getPrimaryColor(categoryId),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: padding),
                          child: LinearProgressIndicator(
                            value:
                                (_currentQuestionIndex + 1) / _questions.length,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              CategoryColors.getPrimaryColor(categoryId),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}