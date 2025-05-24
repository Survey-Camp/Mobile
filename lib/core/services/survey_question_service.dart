import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class SurveyQuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<Map<String, String>> getRandomQuestionFromRandomSurvey() async {
  try {
    // Get current user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get all published surveys
    final surveysSnapshot = await _firestore
        .collection('surveys')
        .where('status', isEqualTo: 'published')
        .get();

    if (surveysSnapshot.docs.isEmpty) {
      throw Exception('No published surveys found');
    }

    // Get completed surveys for the user
    final completedSurveysSnapshot = await _firestore
        .collection('survey_responses')
        .where('userId', isEqualTo: user.uid)
        .get();

    // Create a set of completed survey IDs
    final completedSurveyIds = completedSurveysSnapshot.docs
        .map((doc) => doc.data()['surveyId'] as String)
        .toSet();

    // Filter out completed surveys
    final availableSurveys = surveysSnapshot.docs
        .where((doc) => !completedSurveyIds.contains(doc.id))
        .toList();

    if (availableSurveys.isEmpty) {
      throw Exception('No incomplete surveys available');
    }

    // Get random survey from incomplete surveys
    final random = Random();
    final randomSurvey = availableSurveys[random.nextInt(availableSurveys.length)];
    final surveyData = randomSurvey.data();

    // Get all questions for this survey
    final questionsSnapshot = await _firestore
        .collection('surveys')
        .doc(randomSurvey.id)
        .collection('questions')
        .get();

    if (questionsSnapshot.docs.isEmpty) {
      throw Exception('No questions found for the survey');
    }

    // Get random question
    final randomQuestion = questionsSnapshot.docs[random.nextInt(questionsSnapshot.docs.length)];
    final questionData = randomQuestion.data();

    // Ensure category is properly formatted to match CategoryColors keys
    String category = (surveyData['category'] ?? 'information technology')
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll('/', '');

    return {
      'question': questionData['question'] ?? '',
      'surveyId': randomSurvey.id,
      'category': category,
    };
  } catch (e) {
    print('Error getting random survey question: $e');
    return {
      'question': 'Error loading question',
      'surveyId': '',
      'category': 'information technology', // default category
    };
  }
}


  Future<String?> getThirdQuestionText(String surveyId) async {
    try {
      final questionsSnapshot = await _firestore
          .collection('surveys')
          .doc(surveyId)
          .collection('questions')
          .orderBy('order')
          .limit(3)
          .get();

      if (questionsSnapshot.docs.length >= 3) {
        final thirdQuestionDoc = questionsSnapshot.docs[2];
        final questionData = thirdQuestionDoc.data();
        return questionData['question'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching third question: $e');
      return null;
    }
  }
}