import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:survey_camp/core/constants/api_endpoints.dart';

class QuestionUpdateService {
  /// Generates a similar question based on the provided prompt
  ///
  /// Returns a Future containing a Map with 'original_question' and 'rephrased_question'
  /// or throws an exception if the request fails
  static Future<Map<String, dynamic>> generateSimilarQuestion(
      String prompt) async {
    try {
      final Uri uri = Uri.parse(
          '${ApiEndpoints.updateQuestion}?prompt=${Uri.encodeComponent(prompt)}');

      print('uri: $uri');

      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );
      print(
          'updated question received: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get similar question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating similar question: $e');
    }
  }
}
