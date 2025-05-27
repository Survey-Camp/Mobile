import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_camp/features/survey_responses/widgets/response_card_widget.dart';
import 'package:survey_camp/features/survey_responses/widgets/response_details_dialog.dart';
import '../../../core/models/survey_response_model.dart';
import '../services/survey_response_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';

class ResponseBottomSheet extends StatelessWidget {
  final String surveyId;
  final List<QueryDocumentSnapshot> responses; // Keep this for initial data if needed
  final SurveyResponseService surveyResponseService;

  const ResponseBottomSheet({
    Key? key,
    required this.surveyId,
    required this.responses,
    required this.surveyResponseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Colors.deepPurple;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: surveyResponseService.getSurveyTitle(surveyId),
              builder: (context, snapshot) {
                final title = snapshot.data ?? 'Loading...';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insert_chart_outlined,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '${responses.length} responses collected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // CSV Export Button
                      IconButton(
                        onPressed: () => _exportToCsv(context, title),
                        icon: const Icon(Icons.file_download),
                        tooltip: 'Export to CSV',
                        padding: const EdgeInsets.all(8),
                        style: IconButton.styleFrom(
                          backgroundColor: secondaryColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[200]),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('survey_responses')
                    .where('surveyId', isEqualTo: surveyId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final responses = snapshot.data!.docs;

                  if (responses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No responses yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: responses.length,
                    itemBuilder: (context, index) {
                      final responseData =
                          responses[index].data() as Map<String, dynamic>;
                      final response = SurveyResponse.fromMap(responseData);
                      final isValid = _checkSurveyValidity(response);
                      return ResponseCardWidget(
                        response: response,
                        index: index,
                        isValid: isValid,
                        onTap: () => _showResponseDetails(context, response),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context, String surveyTitle) async {
    // Show confirmation dialog first
    // ignore: use_build_context_synchronously
    final bool? shouldDownload = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Responses'),
          content: const Text('Do you want to download the responses as CSV file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Download
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
              child: const Text('Download'),
            ),
          ],
        );
      },
    );

    // If user cancelled or closed the dialog
    if (shouldDownload != true) {
      return;
    }

    // Show a loading indicator
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Generating CSV file...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Get all responses for this survey
      final querySnapshot = await FirebaseFirestore.instance
          .collection('survey_responses')
          .where('surveyId', isEqualTo: surveyId)
          .get();

      final responses = querySnapshot.docs
          .map((doc) => SurveyResponse.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (responses.isEmpty) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('No responses to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create a CSV structure
      List<List<dynamic>> csvData = [];
      
      // Add header row based on the first response
      List<dynamic> headerRow = [
        'Response ID',
        'Submitted At',
        'User ID',
        'Is Valid'
      ];
      
      // Determine the maximum number of questions
      int maxQuestions = 0;
      for (final response in responses) {
        if (response.responses.length > maxQuestions) {
          maxQuestions = response.responses.length;
        }
      }

      // Add question headers
      for (int i = 0; i < maxQuestions; i++) {
        headerRow.add('Question ${i + 1}');
        headerRow.add('Answer ${i + 1}');
        headerRow.add('Time Spent ${i + 1} (seconds)');
      }
      
      csvData.add(headerRow);

      // Add rows for each response
      for (final response in responses) {
        List<dynamic> row = [
          response.id,
          response.submittedAt.toIso8601String(),
          response.userId,
          response.isValid ? 'Yes' : 'No',
        ];
        
        // Add each question-answer pair
        for (int i = 0; i < maxQuestions; i++) {
          if (i < response.responses.length) {
            final questionResponse = response.responses[i];
            row.add(questionResponse.question);
            row.add(questionResponse.answer);
            row.add(questionResponse.timeSpent);
          } else {
            // Add empty cells for responses that don't have this question
            row.add('');
            row.add('');
            row.add('');
          }
        }
        
        csvData.add(row);
      }

      // Convert to CSV format
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get safe filename from survey title
      String safeTitle = surveyTitle.replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      
      // Format current date for filename
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}";
      
      // Define filename
      final filename = "${safeTitle}_responses_$dateStr.csv";
      
      // Remove temporary file creation code and directly save to downloads
      try {
        // Request storage permission
        if (!await _requestPermission(Permission.storage)) {
          scaffold.showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Get the downloads directory
        Directory? downloadsDir = await DownloadsPathProvider.downloadsDirectory;
        
        // ignore: prefer_conditional_assignment
        if (downloadsDir == null) {
          downloadsDir = await getExternalStorageDirectory();
        }
        
        if (downloadsDir == null) {
          throw Exception("Couldn't access storage directory");
        }
        
        // Create the file in downloads folder
        final file = File('${downloadsDir.path}/$filename');
        await file.writeAsString(csv);
        
        // Show success dialog
        // ignore: use_build_context_synchronously
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Download Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text('File saved to:\n${file.path}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        
      } catch (e) {
        // Show error dialog
        // ignore: use_build_context_synchronously
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Download Failed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: $e'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      
    } catch (e) {
      print('Error exporting CSV: $e');
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      return result.isGranted;
    }
  }

  void _showResponseDetails(BuildContext context, SurveyResponse response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResponseDetailsDialog(
          response: response,
          surveyResponseService: surveyResponseService,
        );
      },
    );
  }

  bool _checkSurveyValidity(SurveyResponse response) {
    return response.isValid;
  }
}