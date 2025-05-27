import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_camp/core/models/survey_model.dart';

final categorySurveysProvider = AsyncNotifierProviderFamily<CategorySurveysNotifier, List<Survey>, String>(() => CategorySurveysNotifier());

class CategorySurveysNotifier extends FamilyAsyncNotifier<List<Survey>, String> {
  @override
  Future<List<Survey>> build(String category) async {
    return _fetchSurveysByCategory(category);
  }

  Future<List<Survey>> _fetchSurveysByCategory(String category) async {
    try {
      final surveysSnapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .where('categoryName', isEqualTo: category)
          .where('status', isEqualTo: 'published')
          .get();

      return surveysSnapshot.docs
          .map((doc) => Survey.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch surveys: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSurveysByCategory(arg));
  }
}