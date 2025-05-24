import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_camp/core/models/survey_model.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';

final surveysProvider = StreamProvider.autoDispose<List<Survey>>((ref) {
  final authState = ref.watch(authProvider);

  return authState.when(
    data: (user) async* {
      if (user == null) {
        yield [];
        return;
      }

      // Get completed surveys for the user
      final completedSurveysSnapshot = await FirebaseFirestore.instance
          .collection('survey_responses')
          .where('userId', isEqualTo: user.uid)
          .get();

      final completedSurveyIds = completedSurveysSnapshot.docs
          .map((doc) => doc.data()['surveyId'] as String)
          .toSet();

      // Stream of surveys excluding completed ones and user's own surveys
      yield* FirebaseFirestore.instance
          .collection('surveys')
          .where('status', isEqualTo: 'published')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .where((doc) =>
                  doc['createdBy'] != user.uid &&
                  !completedSurveyIds.contains(doc.id))
              .map((doc) => Survey.fromFirestore(doc))
              .toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});