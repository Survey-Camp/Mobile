import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:survey_camp/core/constants/api_endpoints.dart';

class SurveyGeneratorService {
  static final SurveyGeneratorService _instance =
      SurveyGeneratorService._internal();
  final http.Client _client;

  /// Factory constructor to maintain singleton instance
  factory SurveyGeneratorService({http.Client? testClient}) {
    if (testClient != null) {
      return SurveyGeneratorService._test(testClient);
    }
    return _instance;
  }

  /// Private constructor for singleton pattern
  SurveyGeneratorService._internal() : _client = http.Client();

  /// Test constructor for dependency injection
  SurveyGeneratorService._test(this._client);

  /// Generates a survey based on the provided prompt
  ///
  /// [prompt] - The text prompt to generate the survey from
  /// Returns a list of survey questions with their respective answer options
  Future<List<Map<String, dynamic>>> generateSurvey(String prompt) async {
    // Only validate that prompt is not empty
    if (prompt.isEmpty) {
      throw ArgumentError('Prompt cannot be empty for survey generation');
    }

    try {
      print('Generating survey with prompt: $prompt');

      final response = await _client.post(
        Uri.parse(ApiEndpoints.generateSurvey),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json'
        },
        body: {'prompt': prompt},
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response received from server');
        }

        try {
          // Try to decode as JSON first
          final dynamic decodedData = jsonDecode(response.body);

          // Handle the case with nested survey_questions
          if (decodedData is Map<String, dynamic> &&
              decodedData.containsKey('survey_questions')) {
            final dynamic surveyQuestions = decodedData['survey_questions'];

            // Handle double-nested survey_questions
            if (surveyQuestions is Map<String, dynamic> &&
                surveyQuestions.containsKey('survey_questions')) {
              return surveyQuestions['survey_questions']
                  .cast<Map<String, dynamic>>();
            }

            // Handle direct survey_questions array
            if (surveyQuestions is List) {
              return surveyQuestions.cast<Map<String, dynamic>>();
            }
          }

          // Handle warning case with raw_response
          if (decodedData is Map<String, dynamic> &&
              decodedData.containsKey('warning') &&
              decodedData.containsKey('raw_response')) {
            // Display the raw response error in the UI
            return [
              {
                'question': decodedData['raw_response'],
                'answer': [
                  {
                    'option': '1',
                    'text': 'Try again with a more specific prompt'
                  }
                ]
              }
            ];
          }

          // If we have a simple list, return it directly
          if (decodedData is List) {
            return decodedData.cast<Map<String, dynamic>>();
          }

          // Fallback: return a simple error message
          return [
            {
              'question': 'Could not process the survey results',
              'answer': [
                {'option': '1', 'text': 'Try again with a different prompt'}
              ]
            }
          ];
        } catch (e) {
          print('JSON parsing error: $e');
          return [
            {
              'question': 'Error parsing response: ${e.toString()}',
              'answer': [
                {'option': '1', 'text': 'Try again with a more specific prompt'}
              ]
            }
          ];
        }
      } else {
        return [
          {
            'question': 'API request failed: ${response.statusCode}',
            'answer': [
              {'option': '1', 'text': 'Try again later'}
            ]
          }
        ];
      }
    } catch (e) {
      print('Survey generation error: $e');
      return [
        {
          'question': 'Network or service error: ${e.toString()}',
          'answer': [
            {'option': '1', 'text': 'Try again later'}
          ]
        }
      ];
    }
  }

  /// Disposes of the HTTP client when the service is no longer needed
  void dispose() {
    if (this != _instance) {
      _client.close();
    }
  }
}
