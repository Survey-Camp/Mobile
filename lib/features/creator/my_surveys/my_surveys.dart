import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:survey_camp/features/creator/create_survey/create_survey_screen.dart';
import 'package:survey_camp/features/creator/create_survey_question/create_survey_question.dart';
import 'package:survey_camp/features/survey_responses/survey_response_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class MySurveysScreen extends ConsumerStatefulWidget {
  const MySurveysScreen({super.key});

  @override
  ConsumerState<MySurveysScreen> createState() => _MySurveysScreenState();
}

class _MySurveysScreenState extends ConsumerState<MySurveysScreen> {
  Stream<QuerySnapshot>? surveysStream;
  bool isIndexError = false;
  Map<String, bool> _loadingPdfs = {}; // Add this line to track loading state for each survey

  Future<int> _getResponseCount(String surveyId) async {
    try {
      final QuerySnapshot responseSnapshot = await FirebaseFirestore.instance
          .collection('survey_responses')
          .where('surveyId', isEqualTo: surveyId)
          .get();

      return responseSnapshot.size;
    } catch (e) {
      print('Error getting response count: $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    setupSurveysStream();
  }

  void setupSurveysStream() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      try {
        surveysStream = FirebaseFirestore.instance
            .collection('surveys')
            .where('createdBy', isEqualTo: user.uid)
            .snapshots();
      } catch (e) {
        print('Error setting up surveys stream: $e');
        setState(() {
          isIndexError = true;
        });
      }
    }
  }

  Future<void> _retryWithIndex() async {
    setState(() {
      isIndexError = false;
    });

    final user = ref.read(authProvider).value;
    if (user != null) {
      surveysStream = FirebaseFirestore.instance
          .collection('surveys')
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Future<void> _updateSurveyStatus(
      String surveyId, String currentStatus) async {
    final bool? shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        String newStatus = currentStatus == 'draft' ? 'published' : 'draft';
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Update Survey Status'),
          content: Text(
            'Are you sure you want to change the survey status to ${newStatus.toUpperCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalettes.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Update'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate == true) {
      try {
        String newStatus = currentStatus == 'draft' ? 'published' : 'draft';
        await FirebaseFirestore.instance
            .collection('surveys')
            .doc(surveyId)
            .update({'status': newStatus});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Survey status updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update survey status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteSurvey(String surveyId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Survey'),
          content: const Text(
            'Are you sure you want to delete this survey? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('surveys')
            .doc(surveyId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Survey deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete survey'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showInsufficientPointsDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Insufficient Points'),
          content: const Text(
            'You need at least 150 points to create a survey. Would you like to get more points?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
              child: const Text('Go to Home'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/shop');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalettes.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Go to Shop'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIndexErrorMessage(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: fontSize * 3, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'One-time Setup Required',
            style: TextStyle(
              fontSize: fontSize * 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please create the required index in Firebase Console.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryWithIndex,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalettes.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final responsive = Responsive(context);
    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;
    double iconSize = responsive.screenWidth * 0.06;
    double padding = responsive.screenWidth * 0.03;

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final user = ref.read(authProvider).value;
              if (user != null) {
                try {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  final totalPoints =
                      (userDoc.data()?['totalPoints'] ?? 0) as int;

                  if (totalPoints >= 150) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateSurveyScreen(),
                      ),
                    );
                  } else {
                    await _showInsufficientPointsDialog();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Error checking points. Please try again.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            backgroundColor: AppPalettes.primary,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Create Survey',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600)),
          ),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.screenWidth * 0.05,
                  vertical: responsive.screenHeight * 0.03,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: iconSize,
                            color: Colors.black87,
                          )),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'My Surveys',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage and track all your created surveys',
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isIndexError)
                      _buildIndexErrorMessage(descriptionFontSize)
                    else
                      _buildSurveysList(descriptionFontSize),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSurveysList(double fontSize) {
    return StreamBuilder<QuerySnapshot>(
      stream: surveysStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final surveys = snapshot.data?.docs ?? [];

        if (surveys.isEmpty) {
          return _buildEmptyState(fontSize);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: surveys.length,
          itemBuilder: (context, index) {
            final survey = surveys[index].data() as Map<String, dynamic>;
            final surveyId = surveys[index].id;

            return FutureBuilder<int>(
              future: _getResponseCount(surveyId),
              builder: (context, responseSnapshot) {
                final responseCount = responseSnapshot.data ?? 0;
                survey['responseCount'] = responseCount;

                return _buildSurveyCard(
                  survey,
                  surveyId,
                  fontSize,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined,
              size: fontSize * 3, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No surveys yet',
            style: TextStyle(
              fontSize: fontSize * 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first survey to get started',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(
      Map<String, dynamic> survey, String surveyId, double fontSize) {
    final status = survey['status'] as String? ?? 'draft';
    final createdAt =
        (survey['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final responses = survey['responseCount'] as int? ?? 0;
    final title = survey['title'] as String? ?? 'Untitled Survey';
    final description = survey['description'] as String? ?? 'No description';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateSurveyQuestionScreen(
                  title: title,
                  description: description,
                  surveyId: surveyId,
                  category: survey['categoryName'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppPalettes.primary.withOpacity(0.04),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildStatusBadge(status, surveyId, fontSize),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              _loadingPdfs[surveyId] == true
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.blue[400]!),
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () =>
                                          _generateAndDownloadPDF(survey, surveyId),
                                      icon: const Icon(Icons.download_outlined),
                                      color: Colors.blue[400],
                                      tooltip: 'Download PDF',
                                    ),
                              IconButton(
                                onPressed: () => _deleteSurvey(surveyId),
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red[400],
                                tooltip: 'Delete Survey',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: fontSize * 1.3,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Colors.black87,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: fontSize * 0.95,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildMetaInfo(
                            icon: Icons.calendar_today_outlined,
                            label: 'Created',
                            value: _formatDate(createdAt),
                            fontSize: fontSize,
                          ),
                          const SizedBox(width: 24),
                          _buildMetaInfo(
                            icon: Icons.category_outlined,
                            label: 'Category',
                            value: survey['categoryName'] ?? 'General',
                            fontSize: fontSize,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurveyResponseScreen(
                                      surveyId: surveyId),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                _buildStatistic(
                                  icon: Icons.how_to_vote_outlined,
                                  value: responses.toString(),
                                  label: 'Responses',
                                  fontSize: fontSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String surveyId, double fontSize) {
    final isPublished = status.toLowerCase() == 'published';

    return InkWell(
      onTap: () => _updateSurveyStatus(surveyId, status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPublished ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPublished ? Colors.green[200]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPublished ? Icons.public : Icons.edit_note,
              size: fontSize,
              color: isPublished ? Colors.green[700] : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: fontSize * 0.85,
                fontWeight: FontWeight.w600,
                color: isPublished ? Colors.green[700] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaInfo({
    required IconData icon,
    required String label,
    required String value,
    required double fontSize,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: fontSize * 0.9,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize * 0.75,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize * 0.85,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistic({
    required IconData icon,
    required String value,
    required String label,
    required double fontSize,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalettes.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: fontSize,
              color: AppPalettes.primary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize * 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required double fontSize,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: fontSize, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize * 0.75,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize * 0.85,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildStatusChip(String status, String surveyId, double fontSize) {
    Color backgroundColor;
    Color textColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'published':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        statusIcon = Icons.public;
        break;
      case 'draft':
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        statusIcon = Icons.edit_note;
    }

    return InkWell(
      onTap: () => _updateSurveyStatus(surveyId, status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              size: fontSize * 0.9,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: fontSize * 0.8,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, pw.Font>> _loadFonts() async {
    try {
      return {
        'regular': await PdfGoogleFonts.nunitoRegular(),
        'bold': await PdfGoogleFonts.nunitoBold(),
      };
    } catch (e) {
      print('Error loading fonts: $e');
      return {
        'regular': await PdfGoogleFonts.robotoRegular(),
        'bold': await PdfGoogleFonts.robotoBold(),
      };
    }
  }

  pw.Widget _buildPdfHeader(pw.Context context, pw.Font font, pw.Font boldFont, String title) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      padding: pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Survey Report',
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Title: $title',
                style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Text(
                'Generated on ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            width: 50,
            height: 50,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'SC',
                style: pw.TextStyle(
                  font: boldFont,
                  color: PdfColors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'SurveyCamp Report',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  Future<void> _generateAndDownloadPDF(Map<String, dynamic> survey, String surveyId) async {
    // Set loading state for this survey
    setState(() {
      _loadingPdfs[surveyId] = true;
    });

    try {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission is required to save PDF');
      }

      final pdf = pw.Document();
      final fonts = await _loadFonts();

      final title = survey['title'] ?? 'Untitled Survey';
      final description = survey['description'] ?? 'No description';
      final category = survey['categoryName'] ?? 'General';
      final surveyStatus = survey['status'] ?? 'draft';
      final responseCount = survey['responseCount'] ?? 0;
      final createdAt = (survey['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Fetch questions
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(surveyId)
          .collection('questions')
          .get();

      // Prepare questions and answers data
      List<Map<String, dynamic>> questionsData = [];
      for (var questionDoc in questionsSnapshot.docs) {
        final questionData = questionDoc.data();
        
        // Fetch answers for each question
        final answersSnapshot = await questionDoc.reference
            .collection('answers')
            .get();

        List<String> answers = answersSnapshot.docs
            .map((doc) => doc.data()['answer'].toString())
            .toList();

        // Fetch options if they exist
        final optionsSnapshot = await questionDoc.reference
            .collection('options')
            .orderBy('order')
            .get();

        List<String> options = optionsSnapshot.docs
            .map((doc) => doc.data()['option'].toString())
            .toList();

        questionsData.add({
          'question': questionData['question'],
          'type': questionData['type'],
          'required': questionData['required'],
          'options': options,
          'answers': answers,
        });
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(context, fonts['regular']!, fonts['bold']!, title),
          footer: (context) => _buildPdfFooter(context, fonts['regular']!),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Text(
              'Survey Details',
              style: pw.TextStyle(
                font: fonts['bold']!,
                fontSize: 18,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Description: $description', 
                style: pw.TextStyle(font: fonts['regular']!, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text('Category: $category', 
                style: pw.TextStyle(font: fonts['regular']!, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text('Status: ${surveyStatus.toUpperCase()}', 
                style: pw.TextStyle(font: fonts['regular']!, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text('Response Count: $responseCount', 
                style: pw.TextStyle(font: fonts['regular']!, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text(
              'Created At: ${_formatDate(createdAt)}',
              style: pw.TextStyle(font: fonts['regular']!, fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Questions and Responses',
              style: pw.TextStyle(
                font: fonts['bold']!,
                fontSize: 18,
              ),
            ),
            pw.SizedBox(height: 10),
            ...questionsData.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> question = entry.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Q${index + 1}. ${question['question']}',
                    style: pw.TextStyle(font: fonts['bold']!, fontSize: 14),
                  ),
                  pw.SizedBox(height: 5),
                  if (question['options'].isNotEmpty) ...[
                    pw.Text(
                      'Options:',
                      style: pw.TextStyle(font: fonts['regular']!, fontSize: 12, color: PdfColors.grey700),
                    ),
                    ...question['options'].map<pw.Widget>((option) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10),
                      child: pw.Text(
                        '• $option',
                        style: pw.TextStyle(font: fonts['regular']!, fontSize: 12),
                      ),
                    )).toList(),
                    pw.SizedBox(height: 5),
                  ],
                  ...question['answers'].map<pw.Widget>((answer) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10),
                    child: pw.Text(
                      '• $answer',
                      style: pw.TextStyle(font: fonts['regular']!, fontSize: 12),
                    ),
                  )).toList(),
                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final fileName = 'survey_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Survey Report',
        subject: fileName,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _loadingPdfs[surveyId] = false;
        });
      }
    }
  }
}