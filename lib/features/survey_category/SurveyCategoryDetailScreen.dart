import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/shared/widgets/fancy_survey_card.dart';
import 'package:survey_camp/shared/widgets/top_bar.dart';
import 'package:survey_camp/shared/theme/category_colors.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:survey_camp/core/providers/category_surveys_provider.dart';


class SurveyCategoryDetailScreen extends ConsumerStatefulWidget {
  final String category;

  const SurveyCategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<SurveyCategoryDetailScreen> createState() =>
      _SurveyCategoryDetailScreenState();
}


class _SurveyCategoryDetailScreenState extends ConsumerState<SurveyCategoryDetailScreen> {
  Set<String> _completedSurveyIds = {};
  StreamSubscription? _responsesSubscription;

  @override
  void initState() {
    super.initState();
    _setupResponsesListener();
  }

  @override
  void dispose() {
    _responsesSubscription?.cancel();
    super.dispose();
  }

  void _setupResponsesListener() {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    _responsesSubscription = FirebaseFirestore.instance
        .collection('survey_responses')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final completedIds = snapshot.docs
            .map((doc) => doc.data()['surveyId'] as String)
            .toSet();
        setState(() {
          _completedSurveyIds = completedIds;
        });
      }
    });
  }

  Future<void> _refreshSurveys() async {
    await ref.read(categorySurveysProvider(widget.category).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final categoryId = widget.category.toLowerCase().replaceAll('/', '');
    final authState = ref.watch(authProvider);
    final surveysAsync = ref.watch(categorySurveysProvider(widget.category));

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: CategoryColors.getLightColor(categoryId),
          body: RefreshIndicator(
            onRefresh: _refreshSurveys,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.screenWidth * 0.05,
                    vertical: responsive.screenHeight * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomTopBar(),
                      const SizedBox(height: 24),
                      Text(
                        widget.category,
                        style: TextStyle(
                          fontSize: responsive.screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: CategoryColors.getDarkColor(categoryId),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Surveys',
                            style: TextStyle(
                              fontSize: responsive.screenWidth * 0.04,
                              color: CategoryColors.getDarkColor(categoryId)
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      surveysAsync.when(
                        data: (surveys) {
                          // Filter out surveys created by current user
                          final filteredSurveys = surveys.where(
                            (survey) => survey.createdBy != user.uid
                          ).toList();

                          return filteredSurveys.isEmpty
                            ? Center(
                                child: Text(
                                  'No surveys available for this category',
                                  style: TextStyle(
                                    color: CategoryColors.getDarkColor(categoryId),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredSurveys.length,
                                itemBuilder: (context, index) {
                                  final survey = filteredSurveys[index];
                                  final isCompleted = _completedSurveyIds.contains(survey.id);

                                  return CategorySurveyCard(
                                    survey: survey,
                                    userId: user.uid,
                                    categoryName: survey.categoryName,
                                    onSurveyCompleted: _refreshSurveys,
                                    isCompleted: isCompleted,
                                  );
                                },
                              );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Error: $error'),
                        ),
                      ),
                    ],
                  ),
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
}