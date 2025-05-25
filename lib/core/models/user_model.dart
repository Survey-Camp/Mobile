import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final int? xpPoints;
  final int? completedSurveys;
  final int? quickSurveys;
  final int? totalPoints;
  final bool isEmailVerified;
  final int createdAt;
  final int lastSeen;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.xpPoints,
    this.completedSurveys,
    this.quickSurveys,
    this.totalPoints,
    required this.isEmailVerified,
    required this.createdAt,
    required this.lastSeen,
  });

  factory AppUser.fromFirebaseUser(firebase.User firebaseUser) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      xpPoints: 0,
      completedSurveys: 0,
      quickSurveys: 0,
      totalPoints: 0,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // In AppUser.fromFirestore
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('DEBUG: Raw Firestore data: $data');

    final user = AppUser(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      xpPoints: data['xpPoints'] ?? 0,
      completedSurveys: data['completedSurveys'] ?? 0,
      quickSurveys: data['quickSurveys'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      lastSeen: data['lastSeen'] ?? DateTime.now().millisecondsSinceEpoch,
    );
    print('DEBUG: Created AppUser with xpPoints: ${user.xpPoints}');
    return user;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'xpPoints': xpPoints,
      'completedSurveys': completedSurveys,
      'quickSurveys': quickSurveys,
      'totalPoints': totalPoints,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    int? xpPoints,
    int? completedSurveys,
    int? quickSurveys,
    int? totalPoints,
    bool? isEmailVerified,
    int? createdAt,
    int? lastSeen,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      xpPoints: xpPoints ?? this.xpPoints,
      completedSurveys: completedSurveys ?? this.completedSurveys,
      quickSurveys: quickSurveys ?? this.quickSurveys,
      totalPoints: totalPoints ?? this.totalPoints,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  AppUser copyWithUpdatedLastSeen() {
    return copyWith(
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoURL == other.photoURL &&
          xpPoints == other.xpPoints &&
          completedSurveys == other.completedSurveys &&
          quickSurveys == other.quickSurveys &&
          totalPoints == other.totalPoints &&
          isEmailVerified == other.isEmailVerified &&
          createdAt == other.createdAt &&
          lastSeen == other.lastSeen;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoURL.hashCode ^
      xpPoints.hashCode ^
      completedSurveys.hashCode ^
      quickSurveys.hashCode ^
      totalPoints.hashCode ^
      isEmailVerified.hashCode ^
      createdAt.hashCode ^
      lastSeen.hashCode;
}
