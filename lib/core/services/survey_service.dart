import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyService {
  final _firestore = FirebaseFirestore.instance;

  Future<bool> checkIfSurveyCompleted(String userId, String surveyId) async {
    final completedSurvey = await _firestore
        .collection('survey_responses')
        .where('userId', isEqualTo: userId)
        .where('surveyId', isEqualTo: surveyId)
        .get();

    return completedSurvey.docs.isNotEmpty;
  }

  Future<String> _getSurveyTitle(String surveyId) async {
  try {
    final surveyDoc = await FirebaseFirestore.instance
        .collection('surveys')
        .doc(surveyId)
        .get();
    
    if (surveyDoc.exists) {
      final data = surveyDoc.data();
      return data?['title'] ?? 'Untitled Survey';
    }
    return 'Survey Not Found';
  } catch (e) {
    return 'Error Loading Survey';
  }
}
}