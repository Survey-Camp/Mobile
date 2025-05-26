import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSurveyCategoriesWithCount() async {
    // Base categories without counts
    final List<Map<String, dynamic>> categories = [
      {'categoryId': 'information technology', 'categoryName': 'Information Technology'},
      {'categoryId': 'agriculture', 'categoryName': 'Agriculture'},
      {'categoryId': 'automobile', 'categoryName': 'Automobile'},
      {'categoryId': 'healthcare', 'categoryName': 'Healthcare'},
      {'categoryId': 'education', 'categoryName': 'Education'},
      {'categoryId': 'environment', 'categoryName': 'Environment'},
      {'categoryId': 'business', 'categoryName': 'Business/Marketing'},
      {'categoryId': 'social', 'categoryName': 'Social Science'},
    ];

    try {
      // Get all published surveys in one query
      final QuerySnapshot surveysSnapshot = await _firestore
          .collection('surveys')
          .where('status', isEqualTo: 'published')
          .get();

      // Create a map to store counts for each category
      Map<String, int> categoryCounts = {};

      // Count surveys for each category
      for (var doc in surveysSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final categoryId = data['categoryId'] as String;
        categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
      }

      // Add counts to categories
      final categoriesWithCount = categories.map((category) {
        return {
          ...category,
          'surveyCount': categoryCounts[category['categoryId']] ?? 0,
        };
      }).toList();

      return categoriesWithCount;
    } catch (e) {
      print('Error fetching survey counts: $e');
      return categories.map((category) => {...category, 'surveyCount': 0}).toList();
    }
  }
}