import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:survey_camp/core/models/survey_model.dart';
import 'package:survey_camp/core/services/ml_api_services.dart';

class UserSurveyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MLApiService _mlService = MLApiService();

  // Main method to fetch survey suggestion
  Future<Survey?> checkAndGetSuggestedSurvey() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return null;
      }

      print('Fetching survey response count for user: ${user.uid}');

      // Step 1: Count the total number of survey responses for the user
      final responseCountSnapshot = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: user.uid)
          .get();

      final surveyCount = responseCountSnapshot.docs.length;
      print('Total survey responses for user: $surveyCount');

      // Step 2: Check if the survey count is a multiple of 5
      if (surveyCount % 5 != 0 || surveyCount == 0) {
        print('Survey count ($surveyCount) is not a multiple of 5 or is zero. No survey suggestion.');
        return null;
      }

      print('Survey count is $surveyCount, proceeding to fetch latest survey response');

      // Step 3: Get the latest survey response for the current user
      final responseSnapshot = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (responseSnapshot.docs.isEmpty) {
        print('No survey responses found for user: ${user.uid}');
        return null;
      }

      final responseData = responseSnapshot.docs.first.data();
      print('Survey response data: $responseData');

      // Step 4: Extract required fields from the survey response
      if (!responseData.containsKey('surveyId')) {
        print('surveyId field missing in survey response');
        return null;
      }
      final lastSurveyId = responseData['surveyId'] as String;

      final userPoints = responseData['Userpoints'] ?? 0;
      final totalDuration = (responseData['totalDuration'] ?? 0).toDouble();
      final responses = responseData['responses'] as List? ?? [];
      final numberOfServerAnswers = responses.length;

      print('Extracted data: userPoints=$userPoints, totalDuration=$totalDuration, numberOfServerAnswers=$numberOfServerAnswers');

      // Step 5: Get the category name from the surveys collection using the surveyId
      final surveyDoc = await _firestore
          .collection('surveys')
          .doc(lastSurveyId)
          .get();

      if (!surveyDoc.exists) {
        print('Survey with ID $lastSurveyId not found');
        return null;
      }

      final surveyData = surveyDoc.data()!;
      print('Survey data: $surveyData');

      if (!surveyData.containsKey('categoryName')) {
        print('categoryName field missing in survey data');
        return null;
      }
      final categoryName = surveyData['categoryName'] as String;

      // Step 6: Call the ML API to get survey suggestion
      print('Calling ML API with: providerServerType=$categoryName, duration=$totalDuration, numberOfServerAnswers=$numberOfServerAnswers, points=$userPoints');
      final prediction = await _mlService.getSurveySuggestion(
        providerServerType: categoryName,
        duration: totalDuration,
        numberOfServerAnswers: numberOfServerAnswers,
        points: userPoints,
      );

      print('ML API response: $prediction');

      // Step 7: Check if a survey should be shown based on the API response
      if (!prediction.containsKey('Suggested Server')) {
        print('Suggested Server missing in ML API response');
        return null;
      }

      final suggestedCategoryName = prediction['Suggested Server'] as String;
      print('Suggested category name from API: $suggestedCategoryName');

      // Step 8: Fetch a survey from the suggested category name
      print('Fetching survey for categoryName: $suggestedCategoryName');
      final suggestedSurveySnapshot = await _firestore
          .collection('surveys')
          .where('categoryName', isEqualTo: suggestedCategoryName)
          .where('status', isEqualTo: 'published')
          .limit(1)
          .get();

      if (suggestedSurveySnapshot.docs.isEmpty) {
        print('No published surveys found for categoryName: $suggestedCategoryName');
        return null;
      }

      // Step 9: Return the suggested survey
      final suggestedSurveyDoc = suggestedSurveySnapshot.docs.first;
      final suggestedSurveyData = suggestedSurveyDoc.data();
      if (!suggestedSurveyData.containsKey('categoryName') || !suggestedSurveyData.containsKey('categoryId')) {
        print('categoryName or categoryId field missing in suggested survey data');
        return null;
      }

      final survey = Survey.fromFirestore(suggestedSurveyDoc);
      print('Suggested survey found: ${survey.title}, categoryName: ${survey.categoryName}, categoryId: ${survey.categoryId}');
      return survey;
      
    } catch (e) {
      print('Error checking for suggested survey: $e');
      return null;
    }
  }
}