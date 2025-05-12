import 'package:survey_camp/core/models/questions_model.dart';

final List<SurveyQuestion> surveyQuestions = [
  SurveyQuestion(
      question: 'What is your primary mode of transportation?',
      answers: ['Car', 'Public Transit', 'Bicycle', 'Walking'],
      correctAnswerIndex: 1),
  SurveyQuestion(
      question: 'How often do you exercise?',
      answers: ['Daily', 'Weekly', 'Monthly', 'Rarely'],
      correctAnswerIndex: 0),
  SurveyQuestion(
      question: 'What is your favorite type of cuisine?',
      answers: ['Italian', 'Chinese', 'Mexican', 'Indian'],
      correctAnswerIndex: 2),
  SurveyQuestion(
      question: 'How do you prefer to spend your free time?',
      answers: ['Reading', 'Watching Movies', 'Sports', 'Socializing'],
      correctAnswerIndex: 3),
  SurveyQuestion(
      question: 'What is your favourite exercise?',
      answers: [
        'assets/images/exercise1.png',
        'assets/images/exercise2.png',
        'assets/images/exercise3.png',
        'assets/images/exercise4.png'
      ],
      questionType: QuestionType.imageChoice,
      correctAnswerIndex: 2),
  SurveyQuestion(
      question: 'Please indicate your weight',
      questionType: QuestionType.scale,
      minValue: 30,
      maxValue: 200,
      initialValue: 70),
  SurveyQuestion(
      question: 'What is your idea about this survey?',
      questionType: QuestionType.textInput)
];
