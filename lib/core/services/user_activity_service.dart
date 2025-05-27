import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_camp/core/models/user_activity_model.dart';

class UserActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserActivity>> getUserRecentActivities(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      return querySnapshot.docs
          .map((doc) => UserActivity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user activities: $e');
    }
  }
}
