import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/survey_response_model.dart';
import '../models/user_activity_model.dart';

class SurveyResponseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> saveSurveyResponse({
    required String userId,
    required String surveyId,
    required List<QuestionResponse> responses,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final surveyDoc = await _firestore.collection('surveys').doc(surveyId).get();
      if (!surveyDoc.exists) {
        throw Exception('Survey document does not exist');
      }
      final surveyTitle = surveyDoc.data()?['title'] ?? 'Unknown Survey';
      
      // Parse datetime strings from metadata
      final startTime = DateTime.parse(metadata['surveyStartTime']);
      final endTime = DateTime.parse(metadata['surveyEndTime']);
      final totalDuration = metadata['totalDuration'];

      final predictionValue = metadata['qualityPrediction'] ?? -1;
      final isValid = predictionValue == 1 ? false : true;

      // Calculate base points and extra points for text input questions
          final questionCount = responses.length;
      int newXpPoints = questionCount * 1; // Base 1 XP per question

      final surveyResponse = SurveyResponse(
        id: _uuid.v4(),
        userId: userId,
        surveyId: surveyId,
        responses: responses,
        submittedAt: DateTime.now(),
        startTime: startTime,
        endTime: endTime,
        totalDuration: totalDuration,
        isValid: isValid,
      );

      // Get points calculated from the survey response
      final calculatedPoints = surveyResponse.toMap()['Userpoints'];

      // Reference to user document
      final userRef = _firestore.collection('users').doc(userId);
      final responseRef = _firestore.collection('survey_responses').doc(surveyResponse.id);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document does not exist');
        }

        final userData = userDoc.data()!;
        final completedSurveys = (userData['completedSurveys'] ?? 0) + 1;

        // Add new points to existing points
        final xpPoints = (userData['xpPoints'] ?? 0) + newXpPoints;
        final totalPoints = (userData['totalPoints'] ?? 0) + calculatedPoints;
        final quickSurveys = (userData['quickSurveys'] ?? 0) + (totalDuration <= 300 ? 1 : 0);

        // Create activities with updated point calculations
        final activities = [
          UserActivity(
            id: _uuid.v4(),
            type: 'points',
            amount: calculatedPoints,
            description: 'Earned $calculatedPoints credits',
            timestamp: DateTime.now(),
          ),
          UserActivity(
            id: _uuid.v4(),
            type: 'xp',
            amount: newXpPoints,
            description: 'Gained ${newXpPoints} XP points',
            timestamp: DateTime.now(),
          ),
          UserActivity(
            id: _uuid.v4(),
            type: 'survey_completed',
            amount: 1,
            description: 'Completed survey: $surveyTitle',
            timestamp: DateTime.now(),
          ),
        ];

        // Update user document
        transaction.update(userRef, {
          'completedSurveys': completedSurveys,
          'xpPoints': xpPoints,
          'totalPoints': totalPoints,
          'quickSurveys': quickSurveys,
        });

        // Save survey response
        transaction.set(responseRef, surveyResponse.toMap());

        // Add activities within the transaction
        for (var activity in activities) {
          final activityRef = userRef.collection('activities').doc(activity.id);
          transaction.set(activityRef, activity.toMap());
        }
      });
    } catch (e) {
      throw Exception('Failed to save survey response: $e');
    }
  }

  Future<List<SurveyResponse>> getUserSurveyResponses(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => SurveyResponse.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user survey responses: $e');
    }
  }
}


