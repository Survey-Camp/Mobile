import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class SurveyFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> saveSurveyQuestions({
    required String surveyId,
    required List<QuestionData> questions,
  }) async {
    final batch = _firestore.batch();

    for (var question in questions) {
      final questionId = _uuid.v4();
      final questionRef = _firestore
          .collection('surveys')
          .doc(surveyId)
          .collection('questions')
          .doc(questionId);

      batch.set(questionRef, {
        'questionId': questionId,
        'question': question.question,
        'type': question.type.toString(),
        'required': question.required,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save options if they exist
      if (question.options.isNotEmpty) {
        for (var i = 0; i < question.options.length; i++) {
          final optionId = _uuid.v4();
          final optionRef = questionRef.collection('options').doc(optionId);

          batch.set(optionRef, {
            'optionId': optionId,
            'option': question.options[i],
            'order': i,
            'imageUrl': question.imageUrls?[i],
          });
        }
      }
    }

    await batch.commit();
  }

  Future<String?> createSurvey({
    required String title,
    required String description,
    String? category,
    required String userId,
  }) async {
    try {
      final surveyRef = _firestore.collection('surveys').doc();
      await surveyRef.set({
        'surveyId': surveyRef.id,
        'title': title,
        'description': description,
        'category': category,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return surveyRef.id;
    } catch (e) {
      debugPrint('Error creating survey: $e');
      return null;
    }
  }

  Future<void> saveAnswer({
    required String surveyId,
    required String questionId,
    required String userId,
    required dynamic answer,
  }) async {
    final answerId = _uuid.v4();
    await _firestore
        .collection('surveys')
        .doc(surveyId)
        .collection('questions')
        .doc(questionId)
        .collection('answers')
        .doc(answerId)
        .set({
      'answerId': answerId,
      'answer': answer,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

