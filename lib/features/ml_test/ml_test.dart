import 'package:flutter/material.dart';
import 'package:survey_camp/core/constants/api_endpoints.dart';
import 'package:survey_camp/core/services/generate_survey.dart';
import 'dart:convert';

import 'package:survey_camp/core/services/ml_api_services.dart';

class MLApiTestScreen extends StatefulWidget {
  const MLApiTestScreen({Key? key}) : super(key: key);

  @override
  _MLApiTestScreenState createState() => _MLApiTestScreenState();
}

class _MLApiTestScreenState extends State<MLApiTestScreen> {
  final MLApiService _mlService = MLApiService();
  final SurveyGeneratorService _surveyService = SurveyGeneratorService();

  bool _isLoading = false;
  String _apiResult = '';
  String _selectedApi = 'Sentiment Analysis';
  String _errorMessage = '';
  String _promptText = '';

  final List<String> _apiOptions = [
    'Sentiment Analysis',
    'Response Quality',
    'Survey Recommendation',
    'Adaptive Personalization',
    'Survey Generator',
    'Survey Suggestion'

  ];

  final TextEditingController _promptController = TextEditingController();
  List<Map<String, dynamic>>? _surveyQuestions;
  bool _hasSurveyError = false;

  @override
  void initState() {
    super.initState();
    _checkApiConnection();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _checkApiConnection() async {
    try {
      print('Checking API connection...');
      await _mlService.predictSentiment('Test message');
      setState(() {
        _errorMessage = '';
      });
      print('API connection successful.');
    } catch (e) {
      setState(() {
        _errorMessage = 'API connection error: $e';
      });
      print('API connection failed: $e');
    }
  }

  // Execute the selected API call with static data
  Future<void> _executeApiCall() async {
    setState(() {
      _isLoading = true;
      _apiResult = '';
      _errorMessage = '';
      _surveyQuestions = null;
      _hasSurveyError = false;
    });

    try {
      dynamic result;

      if (_selectedApi == 'Survey Generator') {
        if (_promptText.isEmpty) {
          throw ArgumentError('Prompt cannot be empty for survey generation');
        }

        result = await _surveyService.generateSurvey(_promptText);
        setState(() {
          if (result is List) {
            _surveyQuestions = List<Map<String, dynamic>>.from(result);
            _apiResult = const JsonEncoder.withIndent('  ').convert(_surveyQuestions);
          } else if (result is Map<String, dynamic> && result.containsKey('error')) {
            _hasSurveyError = true;
            _errorMessage = result['details'] ?? result['error'];
            _apiResult = const JsonEncoder.withIndent('  ').convert(result);
          }
          _isLoading = false;
        });
        return;
      }

      // Handle other API calls
      switch (_selectedApi) {
        case 'Sentiment Analysis':
          result = await _mlService.predictSentiment(
              "This is a test response for sentiment analysis");
          break;
        case 'Response Quality':
          result = await _mlService.predictResponseQuality(
            scrollingBehavior: 2,
            idleTime: 0,
            typingPatterns: 2,
            totalTime: 2,
          );
          break;
        case 'Survey Recommendation':
          result = await _mlService.recommendSurvey(
            userId: 0,
            previousSurveyType: 0,
            responseTime: 0,
            rating: 0,
          );
          break;
        case 'Adaptive Personalization':
          result = await _mlService.predictSurveyQuestions(
            appName: "SurveyApp",
            engagementEndTime: 1715,
            appEngagementDuration: 16,
            previousSurveyKeyArea: "User Experience",
            surveyEngagementTimeUpdate: 3,
            answeredTheSurveyQuestion: "yes",
            ratingInSurvey: 4,
          );
          break;
        case 'Survey Suggestion':
          result = await _mlService.getSurveySuggestion(
            providerServerType: "Agriculture",
            duration: 15,
            numberOfServerAnswers: 5,
            points: 10,
          );
          break;
        default:
          throw Exception('Unknown API selected');
      }

      setState(() {
        if (result is Map<String, dynamic>) {
          if (result.containsKey('error')) {
            _errorMessage = result['details'] ?? result['error'];
          }
          _apiResult = const JsonEncoder.withIndent('  ').convert(result);
        } else if (result is List) {
          _apiResult = const JsonEncoder.withIndent('  ').convert(result);
        } else {
          _apiResult = result.toString();
        }
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _apiResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML API Tester'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message if API connection fails
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Warning: $_errorMessage',
                  style: TextStyle(color: Colors.red[900]),
                ),
              ),

            // API Endpoint Info
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Text(
                'Current Endpoint: ${_getEndpointUrl()}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),

            // API Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select API',
                border: OutlineInputBorder(),
              ),
              value: _selectedApi,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedApi = newValue;
                    _apiResult = '';
                    _surveyQuestions = null;
                    _errorMessage = '';
                    _hasSurveyError = false;
                  });
                }
              },
              items: _apiOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Prompt field for Survey Generator
            if (_selectedApi == 'Survey Generator')
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Enter prompt for survey generation',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Create a customer satisfaction survey',
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _promptText = value;
                  });
                },
              ),

            if (_selectedApi == 'Survey Generator') const SizedBox(height: 16),

            // Static Data Info
            if (_selectedApi != 'Survey Generator')
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'Using static data for $_selectedApi',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 16),

            // Execute Button
            ElevatedButton(
              onPressed: _isLoading ? null : _executeApiCall,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Test $_selectedApi API'),
            ),

            const SizedBox(height: 24),

            // Survey Questions Display
            if (_surveyQuestions != null && !_hasSurveyError) ...[
              const Text('Generated Survey Questions:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _surveyQuestions!.length,
                itemBuilder: (context, index) {
                  final question = _surveyQuestions![index];
                  // Safety check to make sure question has the expected structure
                  if (!question.containsKey('question') ||
                      !question.containsKey('answer')) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.amber[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                            'Invalid question format at index $index: $question'),
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${index + 1}: ${question['question']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...(question['answer'] as List<dynamic>)
                              .map((answer) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  '${answer['option']}. ${answer['text']}'),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Results Section
            const Text('API Response:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: SelectableText(
                _apiResult.isEmpty
                    ? 'API response will appear here'
                    : _apiResult,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Safe method to get the current endpoint URL
  String _getEndpointUrl() {
    try {
      switch (_selectedApi) {
        case 'Sentiment Analysis':
          return ApiEndpoints.sentimentPrediction;
        case 'Response Quality':
          return ApiEndpoints.responseQualityPattern;
        case 'Survey Recommendation':
          return ApiEndpoints.surveyRecommendation;
        case 'Adaptive Personalization':
          return ApiEndpoints.predictSurveyQuestion;
        case 'Survey Generator':
          return ApiEndpoints.generateSurvey;
        case 'Survey Suggestion':
          return ApiEndpoints.surveySuggestion;
        default:
          return 'Unknown endpoint';
      }
    } catch (e) {
      return 'Error retrieving endpoint: $e';
    }
  }
}
