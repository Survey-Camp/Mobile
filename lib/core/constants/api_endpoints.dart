import 'package:survey_camp/config/env_config.dart';

class ApiEndpoints {
  static final String _mlIP = EnvConfig.mlServerIP;

  static String get responseQualityPattern => "http://$_mlIP:8000/predict";
  static String get sentimentPrediction => "http://$_mlIP:8001/predict";
  static String get generateSurvey => "http://$_mlIP:8002/generate_survey/";
  static String get predictSurveyQuestion => "http://$_mlIP:8003/predict/";
  static String get surveyRecommendation => "http://$_mlIP:8004/recommend";
  static String get updateQuestion =>
      "http://$_mlIP:8005/generate_similar_question/";
  static String get surveySuggestion => "http://$_mlIP:8006/predict";
}
