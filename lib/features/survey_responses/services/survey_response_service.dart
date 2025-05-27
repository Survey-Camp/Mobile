import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SurveyResponseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<Map<String, List<QueryDocumentSnapshot>>> getGroupedResponses(
      String? surveyId) async* {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) yield {};

    try {
      // If surveyId is provided, fetch responses for that specific survey
      if (surveyId != null) {
        final responsesSnapshot = await _firestore
            .collection('survey_responses')
            .where('surveyId', isEqualTo: surveyId)
            .get();

        if (responsesSnapshot.docs.isEmpty) {
          yield {};
          return;
        }

        yield {
          surveyId: responsesSnapshot.docs,
        };
        return;
      }

      // Otherwise, fetch all surveys created by the user (existing code)
      final createdSurveys = await _firestore
          .collection('surveys')
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      final createdSurveyIds =
          createdSurveys.docs.map((doc) => doc.id).toList();

      if (createdSurveyIds.isEmpty) {
        yield {};
        return;
      }

      final responsesSnapshot = await _firestore
          .collection('survey_responses')
          .where('surveyId', whereIn: createdSurveyIds)
          .get();

      final groupedResponses = <String, List<QueryDocumentSnapshot>>{};
      for (var doc in responsesSnapshot.docs) {
        final surveyId = doc.data()['surveyId'] as String;
        groupedResponses.putIfAbsent(surveyId, () => []);
        groupedResponses[surveyId]!.add(doc);
      }

      yield groupedResponses;
    } catch (e) {
      print('Error fetching responses: $e');
      yield {};
    }
  }

  Future<String> getSurveyTitle(String surveyId) async {
    try {
      final surveyDoc =
          await _firestore.collection('surveys').doc(surveyId).get();

      if (surveyDoc.exists) {
        final data = surveyDoc.data();
        return data?['title'] ?? 'Untitled Survey';
      }
      return 'Survey Not Found';
    } catch (e) {
      return 'Error Loading Survey';
    }
  }

  String formatDateTime(DateTime dateTime) {
    try {
      return DateFormat.yMMMd().add_jm().format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '$minutes min ${remainingSeconds} sec';
    }
  }

  Future<void> addXpToUser(String userId, int xpAmount) async {
    try {
      // Get user document reference
      final userRef = _firestore.collection('users').doc(userId);

      // Update XP in a transaction
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw 'User document not found';
        }

        final currentXP = userDoc.data()?['xpPoints'] ?? 0;
        final newXP = currentXP + xpAmount;

        transaction.update(userRef, {'xpPoints': newXP});
      });
    } catch (e) {
      throw 'Failed to add XP: $e';
    }
  }

  Future<bool> isSurveyValid(String surveyId) async {
    try {
      final surveyDoc =
          await _firestore.collection('surveys').doc(surveyId).get();

      if (surveyDoc.exists) {
        final data = surveyDoc.data();
        return data?['isValid'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateIsValidStatus(String responseId, bool isValid) async {
    await FirebaseFirestore.instance
        .collection('survey_responses')
        .doc(responseId)
        .update({
      'isValid': isValid,
    });
  }
  Future<bool> checkIfXpGiven(String responseId) async {
    final doc = await _firestore.collection('survey_responses').doc(responseId).get();
    return doc.data()?['xpGiven'] ?? false;
  }

  Future<void> markXpAsGiven(String responseId) async {
    await _firestore.collection('survey_responses').doc(responseId).update({
      'xpGiven': true,
    });
  }
}