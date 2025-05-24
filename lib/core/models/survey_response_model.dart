import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionResponse {
  final String question;
  final String questionType;
  final dynamic answer;
  final int? timeSpent;

  QuestionResponse({
    required this.question,
    required this.questionType,
    required this.answer,
    this.timeSpent,
  });

  Map<String, dynamic> toMap() => {
        'question': question,
        'questionType': questionType,
        'answer': answer,
        'timeSpent': timeSpent,
      };

  factory QuestionResponse.fromMap(Map<String, dynamic> map) {
    return QuestionResponse(
      question: map['question'] as String,
      questionType: map['questionType'] as String,
      answer: map['answer'],
      timeSpent: map['timeSpent'] as int?,
    );
  }
}

class SurveyResponse {
  final String id;
  final String userId;
  final String surveyId;
  final List<QuestionResponse> responses;
  final DateTime submittedAt;
  final DateTime startTime;
  final DateTime endTime;
  final int totalDuration;
  final bool isValid;

  SurveyResponse({
    required this.id,
    required this.userId,
    required this.surveyId,
    required this.responses,
    required this.submittedAt,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.isValid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'surveyId': surveyId,
      'responses': responses.map((response) => response.toMap()).toList(),
      'submittedAt': Timestamp.fromDate(submittedAt),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalDuration': totalDuration,
      'isValid': isValid,
    };
  }

  factory SurveyResponse.fromMap(Map<String, dynamic> map) {
    return SurveyResponse(
      id: map['id'],
      userId: map['userId'],
      surveyId: map['surveyId'],
      responses: (map['responses'] as List)
          .map((response) => QuestionResponse.fromMap(response))
          .toList(),
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.parse(map['submittedAt']),
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.parse(map['startTime']),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.parse(map['endTime']),
      totalDuration: map['totalDuration'],
      isValid: map['isValid'] ?? true,
    );
  }
}
