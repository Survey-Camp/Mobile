import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivity {
  final String id;
  final String type; // 'points', 'xp', 'survey_completed'
  final int amount;
  final String description;
  final DateTime timestamp;

  UserActivity({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    return UserActivity(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      description: map['description'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}