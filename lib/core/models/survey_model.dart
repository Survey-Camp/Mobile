import 'package:cloud_firestore/cloud_firestore.dart';

class Survey {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String createdBy;
  final Timestamp createdAt;
  final String status;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.createdBy,
    required this.createdAt,
    required this.status,
  });

  factory Survey.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Survey(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'status': status,
      };
}
