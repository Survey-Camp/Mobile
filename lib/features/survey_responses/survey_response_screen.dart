

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/app_pallete.dart';
import '../../core/utils/responsive.dart';
import 'widgets/empty_responses_widget.dart';
import 'widgets/error_widget.dart';
import 'widgets/survey_card_widget.dart';
import 'services/survey_response_service.dart';

class SurveyResponseScreen extends StatelessWidget {
  final String? surveyId;
  const SurveyResponseScreen({Key? key, this.surveyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final surveyResponseService = SurveyResponseService();
    
    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;
    double iconSize = responsive.screenWidth * 0.06;
    double padding = responsive.screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.screenWidth * 0.05,
              vertical: responsive.screenHeight * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: iconSize,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title Section
                surveyId != null
                    ? FutureBuilder<String>(
                        future: surveyResponseService.getSurveyTitle(surveyId!),
                        builder: (context, snapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.data ?? 'Loading Survey...',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'View all responses for this survey',
                                style: TextStyle(
                                  fontSize: descriptionFontSize,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Survey Responses',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'View all survey responses',
                            style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                Container(
                  // decoration: BoxDecoration(
                  //   gradient: LinearGradient(
                  //     begin: Alignment.topCenter,
                  //     end: Alignment.bottomCenter,
                  //     colors: [Colors.grey[50]!, Colors.grey[100]!],
                  //   ),
                  // ),
                  child: StreamBuilder<Map<String, List<QueryDocumentSnapshot>>>(
                    stream: surveyResponseService.getGroupedResponses(surveyId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return ResponseErrorWidget(
                          errorMessage: 'Error: ${snapshot.error}',
                          onRetry: () {
                            // Refresh logic
                          },
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppPalettes.accent),
                            strokeWidth: 3,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const EmptyResponsesWidget();
                      }

                      return _buildSurveyList(
                        context,
                        snapshot.data!,
                        surveyResponseService,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyList(
    BuildContext context,
    Map<String, List<QueryDocumentSnapshot>> groupedResponses,
    SurveyResponseService surveyResponseService,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
      itemCount: groupedResponses.length,
      itemBuilder: (context, index) {
        final surveyId = groupedResponses.keys.elementAt(index);
        final responses = groupedResponses[surveyId]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SurveyCardWidget(
            surveyId: surveyId,
            responses: responses,
            surveyResponseService: surveyResponseService,
          ),
        );
      },
    );
  }
}