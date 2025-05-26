import 'dart:io';
import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/core/models/survey_response_model.dart';
import 'package:survey_camp/core/repositories/survey_response_repository.dart';
import 'package:survey_camp/shared/widgets/custom_navbar.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinishDialog {
static void showFinishDialog(
  BuildContext context,
  List<SurveyQuestion> surveyQuestions,
  List<dynamic> userAnswers,
  String surveyId,
  WidgetRef ref,
  Map<String, dynamic> timeMetrics,
  {bool isPoorQuality = false}
) {
  final user = ref.read(authProvider).value;
  if (user == null) {
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  // Pre-generate responses
  final responses = _generateResponses(surveyQuestions, userAnswers, timeMetrics);
  final surveyMetadata = _createSurveyMetadata(user.uid, surveyId, timeMetrics);

  // Show dialog immediately
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: isPoorQuality ? Colors.red.shade50 : Colors.white,
          title: _buildDialogTitle(surveyMetadata, isPoorQuality),
          content: _buildDialogContent(
            surveyQuestions,
            userAnswers,
            surveyMetadata,
            isPoorQuality,
          ),
          actions: _buildDialogActions(
            context,
            user.uid,
            surveyId,
            responses,
            surveyMetadata,
            isPoorQuality,
          ),
        ),
      );
    },
  );
}


  static List<QuestionResponse> _generateResponses(
    List<SurveyQuestion> surveyQuestions,
    List<dynamic> userAnswers,
    Map<String, dynamic> timeMetrics,
  ) {
    return List.generate(surveyQuestions.length, (i) {
      final duration = timeMetrics['questionDurations']?[i.toString()]?.toInt() ?? 0;
      final answer = userAnswers[i];
      
      // Extract sentiment if it exists
      String? sentiment;
      dynamic formattedAnswer = answer;
      
      if (answer is Map && answer.containsKey('sentiment')) {
        // Extract just the sentiment value directly
        sentiment = answer['sentiment']['sentiment'] as String?;
        formattedAnswer = answer['text'];
      }

      return QuestionResponse(
        question: surveyQuestions[i].question,
        questionType: surveyQuestions[i].questionType.toString(),
        answer: _formatAnswer(surveyQuestions[i], formattedAnswer),
        timeSpent: duration,
        sentiment: sentiment, // Pass the sentiment string directly
      );
    });
  }

  static Map<String, dynamic> _createSurveyMetadata(
    String userId,
    String surveyId,
    Map<String, dynamic> timeMetrics,
  ) {
    return {
      'userId': userId,
      'surveyId': surveyId,
      'completedAt': DateTime.now().toIso8601String(),
      'surveyStartTime':
          timeMetrics['surveyStartTime'] ?? DateTime.now().toIso8601String(),
      'surveyEndTime':
          timeMetrics['surveyEndTime'] ?? DateTime.now().toIso8601String(),
      'totalDuration': timeMetrics['totalDuration']?.toInt() ?? 0,
      'questionDurations': timeMetrics['questionDurations'] ?? {},
    };
  }

static Widget _buildDialogTitle(
  Map<String, dynamic> surveyMetadata,
  bool isPoorQuality,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Survey Results',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPoorQuality ? Colors.red : Colors.deepPurple,
          fontSize: 24,
        ),
      ),
      if (isPoorQuality) ...[
        const SizedBox(height: 8),
        const Text(
          'Warning: Low quality responses detected',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
      const SizedBox(height: 8),
      // Text(
      //   _formatSurveyDuration(surveyMetadata['totalDuration'] as int),
      //   style: TextStyle(
      //     fontSize: 14,
      //     color: Colors.grey[600],
      //     fontWeight: FontWeight.normal,
      //   ),
      // ),
    ],
  );
}

static Widget _buildDialogContent(
  List<SurveyQuestion> surveyQuestions,
  List<dynamic> userAnswers,
  Map<String, dynamic> surveyMetadata,
  bool isPoorQuality,
) {
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(surveyQuestions.length, (index) {
              final question = surveyQuestions[index];
              final userAnswer = userAnswers[index];
              final questionDuration =
                  (surveyMetadata['questionDurations'] as Map)[index.toString()]
                          ?.toInt() ??
                      0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.question}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAnswerDisplay(question, userAnswer),
                    // SizedBox(
                    //   height: 0,
                    //   width: 0,
                    //   child: Text(
                    //     'Time spent: ${_formatDuration(questionDuration)}',
                    //   ),
                    // ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

static List<Widget> _buildDialogActions(
  BuildContext context,
  String userId,
  String surveyId,
  List<QuestionResponse> responses,
  Map<String, dynamic> surveyMetadata,
  bool isPoorQuality,
) {
  return [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Review'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: isPoorQuality ? Colors.red : Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Submit',
            style: TextStyle(fontSize: 16),
          ),
          onPressed: () => _handleSubmit(
              context, userId, surveyId, responses, surveyMetadata),
        ),
      ],
    ),
  ];
}

  static Future<void> _handleSubmit(
    BuildContext context,
    String userId,
    String surveyId,
    List<QuestionResponse> responses,
    Map<String, dynamic> surveyMetadata,
  ) async {
    _showLoadingDialog(context);

    try {

    final qualityPrediction = surveyMetadata['qualityPrediction'] ?? -1;
    surveyMetadata['qualityPrediction'] = qualityPrediction;

      await _saveSurveyResponse(
        userId: userId,
        surveyId: surveyId,
        responses: responses,
        metadata: surveyMetadata,
      );

      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pop(); // Close results dialog
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const CustomBottomNavbar(),
        ),
        (Route route) => false,
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, e.toString());
    }
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
              SizedBox(height: 16),
              Text(
                'Saving your responses...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Failed to save responses: $errorMessage',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _saveSurveyResponse({
    required String userId,
    required String surveyId,
    required List<QuestionResponse> responses,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await SurveyResponseRepository().saveSurveyResponse(
        userId: userId,
        surveyId: surveyId,
        responses: responses,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Failed to save survey response: $e');
    }
  }

  // static String _formatSurveyDuration(int seconds) {
  //   int minutes = seconds ~/ 60;
  //   int remainingSeconds = seconds % 60;
  //   return 'Completion Time: ${minutes}m ${remainingSeconds}s';
  // }

  // static String _formatDuration(int seconds) {
  //   if (seconds < 60) {
  //     return '$seconds seconds';
  //   } else {
  //     int minutes = seconds ~/ 60;
  //     int remainingSeconds = seconds % 60;
  //     return '$minutes min ${remainingSeconds} sec';
  //   }
  // }

  static dynamic _formatAnswer(SurveyQuestion question, dynamic userAnswer) {
    switch (question.questionType) {
      case QuestionType.range:
        if (userAnswer is Map) {
          return {
            'text': userAnswer['text'] ?? 'No answer selected',
            'imageUrl': userAnswer['imageUrl']
          };
        }
        return userAnswer != null &&
                userAnswer >= 0 &&
                userAnswer < question.answers.length
            ? question.answers[userAnswer]
            : 'No answer selected';
      case QuestionType.multipleChoice:
      case QuestionType.choice:
      case QuestionType.imageChoice:
      case QuestionType.checkbox:
      case QuestionType.imageCheckbox:
        return userAnswer != null &&
                userAnswer >= 0 &&
                userAnswer < question.answers.length
            ? question.answers[userAnswer]
            : null;
      case QuestionType.scale:
      case QuestionType.slider:
        return userAnswer?.round();
      case QuestionType.textInput:
      case QuestionType.paragraph:
      case QuestionType.openEnded:
        return userAnswer?.toString() ?? '';
      default:
        return userAnswer;
    }
  }

  static Widget _buildAnswerDisplay(
      SurveyQuestion question, dynamic userAnswer) {
    String displayAnswer;
    String? imageUrl;

    switch (question.questionType) {
      case QuestionType.range:
        if (userAnswer is Map) {
          displayAnswer = userAnswer['text'] ?? 'No answer selected';
          imageUrl = userAnswer['imageUrl'];
        } else {
          displayAnswer = (userAnswer != null &&
                  userAnswer >= 0 &&
                  userAnswer < question.answers.length)
              ? question.answers[userAnswer]
              : 'No answer selected';
        }
        break;
      case QuestionType.multipleChoice:
      case QuestionType.choice:
      case QuestionType.imageChoice:
      case QuestionType.checkbox:
      case QuestionType.imageCheckbox:
        displayAnswer = (userAnswer != null &&
                userAnswer >= 0 &&
                userAnswer < question.answers.length)
            ? question.answers[userAnswer]
            : 'No answer selected';
        break;
      case QuestionType.scale:
      case QuestionType.slider:
        displayAnswer =
            userAnswer != null ? '${userAnswer.round()}' : 'No value selected';
        break;
      case QuestionType.textInput:
      case QuestionType.paragraph:
      case QuestionType.openEnded:
        if (userAnswer is Map) {
          displayAnswer = userAnswer['text']?.toString() ?? 'No answer provided';
        } else {
          displayAnswer = userAnswer?.toString() ?? 'No answer provided';
        }
        break;
      default:
        displayAnswer = userAnswer?.toString() ?? 'No answer';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          Container(
            width: 80,
            height: 80,
            margin: EdgeInsets.only(bottom: 8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.file(
                  File(imageUrl!),
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ],
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87),
            children: [
              const TextSpan(
                text: 'Your Answer: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: displayAnswer),
            ],
          ),
        ),
      ],
    );
  }
}


