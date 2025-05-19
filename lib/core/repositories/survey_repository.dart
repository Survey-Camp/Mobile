import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:survey_camp/core/models/questions_model.dart';
import 'package:survey_camp/core/utils/survey_helpers.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';

class SurveyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  static const _collections = SurveyCollections();
  static const _fields = SurveyFields();

  SurveyRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _uuid = uuid ?? const Uuid();

  // Create a new survey
  Future<String?> createSurvey({
    required String title,
    required String description,
    String? category,
  }) async {
    try {
      final surveyRef = _firestore.collection(_collections.survey).doc();
      await surveyRef.set({
        _fields.surveyId: surveyRef.id,
        _fields.title: title,
        _fields.description: description,
        _fields.category: category,
        _fields.createdAt: FieldValue.serverTimestamp(),
      });
      return surveyRef.id;
    } catch (e) {
      debugPrint('Error creating survey: $e');
      return null;
    }
  }

  Future<QuestionData> _loadScaleQuestion(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final optionsSnapshot = await _getOptionsQuery(doc.reference).get();
    final List<String> options = [];

    // For scale questions, we need to preserve the order
    final List<MapEntry<int, String>> sortedOptions = [];

    for (var optionDoc in optionsSnapshot.docs) {
      final optionData = optionDoc.data();
      final option = optionData[_fields.option] as String;
      final order = optionData[_fields.order] as int;

      sortedOptions.add(MapEntry(order, option));
    }

    // Sort the options by their order
    sortedOptions.sort((a, b) => a.key.compareTo(b.key));

    // Extract the sorted options
    options.addAll(sortedOptions.map((e) => e.value));

    // Make sure to use the correct parameter names that match your QuestionData constructor
    return QuestionData(
      question: data[_fields.question],
      type: QuestionType.scale,
      options: options,
      required: data[_fields.required] ?? false,
      minValue:
          data[_fields.minValue] != null ? data[_fields.minValue] as int : 1,
      maxValue:
          data[_fields.maxValue] != null ? data[_fields.maxValue] as int : 5,
      minLabel: data[_fields.minLabel] as String? ?? '',
      maxLabel: data[_fields.maxLabel] as String? ?? '',
    );
  }

// Modify your _loadQuestionData method to handle scale questions:
  Future<QuestionData> _loadQuestionData(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final type = _parseQuestionType(data[_fields.type] as String);

    // Handle text input questions
    if (type == QuestionType.textInput || type == QuestionType.paragraph) {
      return _loadTextInputQuestion(data, type);
    }

    // Handle range questions
    if (type == QuestionType.range) {
      return await _loadRangeQuestion(doc, data);
    }

    // Handle scale questions (add this)
    if (type == QuestionType.scale) {
      return await _loadScaleQuestion(doc, data);
    }

    // Handle choice-based questions
    return await _loadChoiceQuestion(doc, data, type);
  }

// Add a method to save scale questions in the _saveQuestionTransaction method
  Future<void> _saveQuestionTransaction(String surveyId, QuestionData question,
      int index, Transaction transaction) async {
    final questionId = _uuid.v4();
    final questionRef = _getQuestionReference(surveyId, questionId);

    final questionData = {
      _fields.surveyId: questionId,
      _fields.question: question.question,
      _fields.type: question.type.toString(),
      _fields.required: question.required,
      _fields.order: index,
      _fields.createdAt: FieldValue.serverTimestamp(),
    };

    // Add scale-specific fields if applicable
    if (question.type == QuestionType.scale) {
      questionData[_fields.minValue] = question.minValue ?? 1;
      questionData[_fields.maxValue] = question.maxValue ?? 5;
      questionData[_fields.minLabel] = question.minLabel ?? '';
      questionData[_fields.maxLabel] = question.maxLabel ?? '';
    }

    // Rest of your existing code...

    // Handle image URLs for image choice questions
    if ((question.type == QuestionType.imageChoice ||
            question.type == QuestionType.imageMultipleChoice) &&
        question.imageUrls != null) {
      // Existing image handling code...
    }

    // For range questions, only save useImages flag
    if (question.type == QuestionType.range && question.useImages == true) {
      questionData[_fields.useImages] = true;
    }

    // Save the question
    transaction.set(questionRef, questionData);

    // Save options with their respective images
    await _saveQuestionOptionsTransaction(
      question,
      questionRef,
      transaction,
      surveyId,
    );
  }

  // Load all questions for a survey
  Future<List<QuestionData>> loadQuestions(String surveyId) async {
    final questionsSnapshot = await _getQuestionsQuery(surveyId).get();
    final List<QuestionData> questions = [];

    for (var doc in questionsSnapshot.docs) {
      final question = await _loadQuestionData(doc);
      questions.add(question);
    }
    return questions;
  }

  Future<void> saveQuestions(
    String surveyId,
    List<QuestionData> questions,
  ) async {
    try {
      // First, load existing questions to compare
      final existingQuestions = await loadQuestions(surveyId);

      // Check if questions are actually different
      if (_areQuestionsEqual(existingQuestions, questions)) {
        return; // No changes to save
      }

      await _firestore.runTransaction((transaction) async {
        // Delete existing questions and options
        final existingQuestionsQuery = _getQuestionsQuery(surveyId);
        final existingQuestionsSnapshot = await existingQuestionsQuery.get();

        for (var doc in existingQuestionsSnapshot.docs) {
          // Delete associated options
          final optionsQuery = doc.reference.collection(_collections.option);
          final optionDocs = await optionsQuery.get();
          for (var optionDoc in optionDocs.docs) {
            transaction.delete(optionDoc.reference);
          }

          // Delete the question
          transaction.delete(doc.reference);
        }

        // Save new questions
        for (var i = 0; i < questions.length; i++) {
          await _saveQuestionTransaction(
              surveyId, questions[i], i, transaction);
        }
      });
    } catch (e) {
      debugPrint('Error saving questions: $e');
      rethrow;
    }
  }

// Helper method to compare questions
  bool _areQuestionsEqual(
      List<QuestionData> existingQuestions, List<QuestionData> newQuestions) {
    if (existingQuestions.length != newQuestions.length) return false;

    for (int i = 0; i < existingQuestions.length; i++) {
      final existing = existingQuestions[i];
      final newQuestion = newQuestions[i];

      // Compare basic question properties
      if (existing.question != newQuestion.question ||
          existing.type != newQuestion.type ||
          existing.required != newQuestion.required) {
        return false;
      }

      // Compare options
      if (existing.type == QuestionType.range) {
        // Compare range options
        if (!_compareRangeOptions(
            existing.rangeOptions, newQuestion.rangeOptions)) {
          return false;
        }
      } else if (existing.type != QuestionType.textInput &&
          existing.type != QuestionType.paragraph) {
        // Compare choice options
        if (!_listEquals(existing.options, newQuestion.options)) {
          return false;
        }
      }

      // Compare image URLs if applicable
      if ((existing.type == QuestionType.imageChoice ||
              existing.type == QuestionType.imageMultipleChoice) &&
          !_compareImageUrls(existing.imageUrls, newQuestion.imageUrls)) {
        return false;
      }
    }

    return true;
  }

// Helper to compare range options
  bool _compareRangeOptions(
      List<RangeOption>? existing, List<RangeOption>? newOptions) {
    if (existing == null && newOptions == null) return true;
    if (existing == null || newOptions == null) return false;
    if (existing.length != newOptions.length) return false;

    for (int i = 0; i < existing.length; i++) {
      if (existing[i].text != newOptions[i].text ||
          existing[i].imageUrl != newOptions[i].imageUrl ||
          existing[i].value != newOptions[i].value) {
        return false;
      }
    }

    return true;
  }

// Helper to compare image URLs
  bool _compareImageUrls(
      Map<int, String>? existing, Map<int, String>? newUrls) {
    if (existing == null && newUrls == null) return true;
    if (existing == null || newUrls == null) return false;
    if (existing.length != newUrls.length) return false;

    return existing.keys.every((key) => existing[key] == newUrls[key]);
  }

// Utility list comparison
  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Load text input question
  QuestionData _loadTextInputQuestion(
    Map<String, dynamic> data,
    QuestionType type,
  ) {
    return QuestionData(
      question: data[_fields.question],
      type: type,
      options: [],
      required: data[_fields.required] ?? false,
    );
  }

  // Load range-based question
  Future<QuestionData> _loadRangeQuestion(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final optionsSnapshot = await _getOptionsQuery(doc.reference).get();
    final List<RangeOption> rangeOptions = [];

    for (var optionDoc in optionsSnapshot.docs) {
      final optionData = optionDoc.data();
      final rangeOption = RangeOption(
        text: optionData[_fields.text] ?? '',
        imageUrl: optionData[_fields.imageUrl] ?? '',
        value: (optionData[_fields.order] is num
            ? (optionData[_fields.order] as num).toDouble()
            : 0.0),
      );
      rangeOptions.add(rangeOption);
    }

    return QuestionData(
      question: data[_fields.question],
      type: QuestionType.range,
      rangeOptions: rangeOptions,
      useImages: data[_fields.useImages] ?? false,
      required: data[_fields.required] ?? false,
    );
  }

  // Load choice-based question
  Future<QuestionData> _loadChoiceQuestion(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    QuestionType type,
  ) async {
    final optionsSnapshot = await _getOptionsQuery(doc.reference).get();
    final options = optionsSnapshot.docs
        .map((optionDoc) => optionDoc.data()[_fields.option] as String)
        .toList();

    return QuestionData(
      question: data[_fields.question],
      type: type,
      options: options,
      imageUrls: _extractImageUrls(data, type),
      required: data[_fields.required] ?? false,
    );
  }

  // Save question options in a transaction
  Future<void> _saveQuestionOptionsTransaction(
    QuestionData question,
    DocumentReference questionRef,
    Transaction transaction,
    String surveyId,
  ) async {
    if (question.type == QuestionType.range) {
      // Save range options with images
      for (var j = 0; j < question.rangeOptions.length; j++) {
        final option = question.rangeOptions[j];
        final optionId = _uuid.v4();
        final optionRef = _getOptionReference(questionRef, optionId);

        String? processedImageUrl;
        if (option.imageUrl != null && option.imageUrl!.isNotEmpty) {
          if (option.imageUrl!.startsWith('file://') ||
              File(option.imageUrl!).existsSync()) {
            processedImageUrl =
                await _uploadImageToStorage(File(option.imageUrl!), surveyId);
          } else if (option.imageUrl!.startsWith('http') ||
              option.imageUrl!.startsWith('https')) {
            processedImageUrl = option.imageUrl;
          }
        }

        final optionData = {
          _fields.optionId: optionId,
          _fields.order: option.value ?? j.toDouble(),
          _fields.text: option.text ?? '',
          if (processedImageUrl != null) _fields.imageUrl: processedImageUrl,
        };

        transaction.set(optionRef, optionData);
      }
    } else if (question.type != QuestionType.textInput &&
        question.type != QuestionType.paragraph &&
        question.options.isNotEmpty) {
      // Save regular choice options
      for (var j = 0; j < question.options.length; j++) {
        final optionId = _uuid.v4();
        final optionRef = _getOptionReference(questionRef, optionId);

        final optionData = {
          _fields.optionId: optionId,
          _fields.option: question.options[j],
          _fields.order: j,
        };

        transaction.set(optionRef, optionData);
      }
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImageToStorage(File imageFile, String surveyId) async {
    try {
      final fileName = '${surveyId}_${path.basename(imageFile.path)}';
      final reference = _storage.ref().child('survey_images/$fileName');

      final uploadTask = await reference.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Parse question type from string
  QuestionType _parseQuestionType(String typeStr) {
    return QuestionType.values.firstWhere(
      (type) => type.toString() == typeStr,
      orElse: () => QuestionType.multipleChoice,
    );
  }

  // Extract image URLs for image-based questions
  Map<int, String>? _extractImageUrls(
    Map<String, dynamic> data,
    QuestionType type,
  ) {
    if (type == QuestionType.imageChoice ||
        type == QuestionType.imageMultipleChoice) {
      final urls = data[_fields.imageUrls];
      if (urls is Map) {
        return Map<int, String>.from(urls
            .map((key, value) => MapEntry(int.parse(key.toString()), value)));
      }
      return null;
    }
    return null;
  }

  // Helper methods for getting references
  DocumentReference _getQuestionReference(String surveyId, String questionId) {
    return _firestore
        .collection(_collections.survey)
        .doc(surveyId)
        .collection(_collections.question)
        .doc(questionId);
  }

  DocumentReference _getOptionReference(
    DocumentReference questionRef,
    String optionId,
  ) {
    return questionRef.collection(_collections.option).doc(optionId);
  }

  Query<Map<String, dynamic>> _getQuestionsQuery(String surveyId) {
    return _firestore
        .collection(_collections.survey)
        .doc(surveyId)
        .collection(_collections.question)
        .orderBy(_fields.order);
  }

  Query<Map<String, dynamic>> _getOptionsQuery(DocumentReference reference) {
    return reference.collection(_collections.option).orderBy(_fields.order);
  }
}
