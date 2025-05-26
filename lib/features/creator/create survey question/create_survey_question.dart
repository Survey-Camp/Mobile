import 'package:flutter/material.dart';
import 'package:survey_camp/core/constants/constants.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/core/repositories/survey_repository.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/bottom_actions.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/questions.dart';
import 'package:survey_camp/features/creator/create_survey_question/widgets/screen_header.dart';
import 'package:survey_camp/features/creator/my_surveys/my_surveys.dart';

class CreateSurveyQuestionScreen extends StatefulWidget {
  final String title;
  final String description;
  final String? category;
  final String? surveyId;

  const CreateSurveyQuestionScreen({
    super.key,
    required this.title,
    required this.description,
    this.category,
    this.surveyId,
  });

  @override
  State<CreateSurveyQuestionScreen> createState() =>
      _CreateSurveyQuestionScreenState();
}

class _CreateSurveyQuestionScreenState
    extends State<CreateSurveyQuestionScreen> {
  final List<QuestionData> _questions = [];
  final SurveyRepository _repository = SurveyRepository();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingQuestions = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.dispose();
    _initializeQuestions();
  }

  Future<void> _initializeQuestions() async {
    if (widget.surveyId != null) {
      await _loadExistingQuestions();
    } else {
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  Future<void> _loadExistingQuestions() async {
    try {
      final loadedQuestions = await _repository.loadQuestions(widget.surveyId!);
      setState(() {
        _questions.clear();
        _questions.addAll(loadedQuestions);
      });
    } catch (e) {
      _handleError('Error loading questions: $e');
    } finally {
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      _error = errorMessage;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _handleSaveSurvey() async {
    if (_questions.isEmpty) {
      setState(() {
        _error = 'Please add at least one question';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String surveyId = widget.surveyId ?? await _createNewSurvey() ?? '';
      await _repository.saveQuestions(surveyId, _questions);
      _showSuccessAndNavigateBack();
    } catch (e) {
      setState(() {
        _error = 'Error saving survey: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _createNewSurvey() async {
    return await _repository.createSurvey(
      title: widget.title,
      description: widget.description,
      category: widget.category,
    );
  }

  void _showSuccessAndNavigateBack() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey saved successfully!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MySurveysScreen()),
        ModalRoute.withName('/home'),
      );
    }
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(QuestionData(
        question: '',
        type: QuestionType.multipleChoice,
        options: ['Option 1'],
        required: false,
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    double iconSize = responsive.screenWidth * 0.06;
    double padding = responsive.screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CreateQuestionsScreenHeader(
              title: widget.title,
              description: widget.description,
              responsive: responsive,
              padding: padding,
              iconSize: iconSize,
            ),
            if (_error != null)
              _ErrorDisplay(error: _error!, responsive: responsive),
            _QuestionsList(
              isLoading: _isLoadingQuestions,
              questions: _questions,
              responsive: responsive,
              scrollController: _scrollController,
              onUpdateQuestion: (index, question) {
                setState(() {
                  _questions[index] = question;
                });
              },
              onDeleteQuestion: _deleteQuestion,
            ),
            CreateQuestionsBottomActions(
              isLoading: _isLoading,
              responsive: responsive,
              onAddQuestion: _addNewQuestion,
              onSaveSurvey: _handleSaveSurvey,
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Widgets
class _ErrorDisplay extends StatelessWidget {
  final String error;
  final Responsive responsive;

  const _ErrorDisplay({
    required this.error,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.screenWidth * 0.04,
      ),
      child: Text(
        error,
        style: const TextStyle(
          color: Colors.red,
          fontSize: Constants.errorFontSize,
        ),
      ),
    );
  }
}

class _QuestionsList extends StatelessWidget {
  final bool isLoading;
  final List<QuestionData> questions;
  final Responsive responsive;
  final Function(int, QuestionData) onUpdateQuestion;
  final Function(int) onDeleteQuestion;
  final ScrollController scrollController;

  const _QuestionsList({
    required this.isLoading,
    required this.questions,
    required this.responsive,
    required this.onUpdateQuestion,
    required this.onDeleteQuestion,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(responsive.screenWidth * 0.02),
        itemCount: questions.length,
        itemBuilder: (context, index) => _buildQuestionCard(index),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: Constants.verticalSpacing,
        horizontal: Constants.horizontalSpacing,
      ),
      child: QuestionCard(
        questionData: questions[index],
        onUpdate: (updatedQuestion) => onUpdateQuestion(index, updatedQuestion),
        onDelete: () => onDeleteQuestion(index),
      ),
    );
  }
}
