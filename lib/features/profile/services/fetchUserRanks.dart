import 'package:cloud_firestore/cloud_firestore.dart';

class UserRankings {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> getUserRankings() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .get();

      List<Map<String, dynamic>> rankedUsers = [];

      int rank = 1;
      int previousPoints = -1;
      int sameRankCount = 0;

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final userData = querySnapshot.docs[i].data();
        final userId = querySnapshot.docs[i].id;
        final totalPoints = userData['totalPoints'] ?? 0;

        if (i > 0 && totalPoints == previousPoints) {
          sameRankCount++;
        } else {
          rank = i + 1 - sameRankCount;
          sameRankCount = 0;
        }

        previousPoints = totalPoints;

        rankedUsers.add({
          'uid': userId,
          'displayName': userData['displayName'] ?? 'Anonymous User',
          'email': userData['email'] ?? '',
          'photoURL': userData['photoURL'] ?? '',
          'totalPoints': totalPoints,
          'xpPoints': userData['xpPoints'] ?? 0,
          'completedSurveys': userData['completedSurveys'] ?? 0,
          'quickSurveys': userData['quickSurveys'] ?? 0,
          'rank': rank
        });
      }

      return rankedUsers;
    } catch (e) {
      print('Error fetching user rankings: $e');
      throw Exception('Failed to fetch user rankings: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserRank(String userId) async {
    try {
      // Get all users ordered by totalPoints in descending order
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .get();

      List<Map<String, dynamic>> rankedUsers = [];
      int currentUserRank = 1;
      int previousPoints = -1;
      int sameRankCount = 0;
      Map<String, dynamic>? currentUserData;

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final userData = doc.data();
        final totalPoints = userData['totalPoints'] is String
            ? int.tryParse(userData['totalPoints'] ?? '0') ?? 0
            : (userData['totalPoints'] ?? 0);

        // Determine rank
        if (i > 0 && totalPoints == previousPoints) {
          sameRankCount++;
        } else {
          currentUserRank = i + 1 - sameRankCount;
        }

        // Store the previous points for comparison
        previousPoints = totalPoints;

        // Create user data map
        final userDataMap = {
          'uid': doc.id,
          'displayName': userData['displayName'] ?? 'Anonymous User',
          'email': userData['email'] ?? '',
          'photoURL': userData['photoURL'] ?? '',
          'totalPoints': totalPoints,
          'xpPoints': userData['xpPoints'] ?? 0,
          'completedSurveys': userData['completedSurveys'] ?? 0,
          'quickSurveys': userData['quickSurveys'] ?? 0,
          'rank': currentUserRank
        };

        // Store current user's data if this is their document
        if (doc.id == userId) {
          currentUserData = userDataMap;
        }

        // Store top 3 users
        if (rankedUsers.length < 3) {
          rankedUsers.add(userDataMap);
        }
      }

      // If user not found, create default data
      if (currentUserData == null) {
        currentUserData = {
          'uid': userId,
          'rank': querySnapshot.docs.length + 1,
          'totalPoints': 0,
          'displayName': 'User not found',
          'photoURL': '',
          'email': '',
          'xpPoints': 0,
          'completedSurveys': 0,
          'quickSurveys': 0,
        };
      }

      return {
        'user': currentUserData,
        'topUsers': rankedUsers,
        'totalUsers': querySnapshot.docs.length
      };
    } catch (e) {
      print('Error getting user rank: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTop10UserRankings() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> rankedUsers = [];

      int rank = 1;
      int previousPoints = -1;
      int sameRankCount = 0;

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final userData = querySnapshot.docs[i].data();
        final userId = querySnapshot.docs[i].id;
        // Convert totalPoints to int if it's a String
        final totalPoints = userData['totalPoints'] is String 
            ? int.tryParse(userData['totalPoints'] ?? '0') ?? 0 
            : (userData['totalPoints'] ?? 0);
        // Convert other numeric fields
        final xpPoints = userData['xpPoints'] is String
            ? int.tryParse(userData['xpPoints'] ?? '0') ?? 0
            : (userData['xpPoints'] ?? 0);
        final completedSurveys = userData['completedSurveys'] is String
            ? int.tryParse(userData['completedSurveys'] ?? '0') ?? 0
            : (userData['completedSurveys'] ?? 0);
        final quickSurveys = userData['quickSurveys'] is String
            ? int.tryParse(userData['quickSurveys'] ?? '0') ?? 0
            : (userData['quickSurveys'] ?? 0);

        if (i > 0 && totalPoints == previousPoints) {
          sameRankCount++;
        } else {
          rank = i + 1 - sameRankCount;
          sameRankCount = 0;
        }

        previousPoints = totalPoints;

        rankedUsers.add({
          'uid': userId,
          'displayName': userData['displayName'] ?? 'Anonymous User',
          'email': userData['email'] ?? '',
          'photoURL': userData['photoURL'] ?? '',
          'totalPoints': totalPoints,
          'xpPoints': xpPoints,
          'completedSurveys': completedSurveys,
          'quickSurveys': quickSurveys,
          'rank': rank
        });
      }

      return rankedUsers;
    } catch (e) {
      print('Error fetching top 10 user rankings: $e');
      throw Exception('Failed to fetch top 10 user rankings: $e');
    }
  }
}