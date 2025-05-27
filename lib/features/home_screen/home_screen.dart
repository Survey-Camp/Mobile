import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/core/models/user_model.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/shared/widgets/header.dart';
import 'package:survey_camp/shared/widgets/top_bar.dart';
import 'package:survey_camp/shared/widgets/survey_card.dart';
import 'package:survey_camp/core/providers/survey_provider.dart';

class SurveyScreen extends ConsumerStatefulWidget{
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  Future<void> _refreshSurveys() async {
    // ref.refresh(surveysProvider);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final surveysAsync = ref.watch(surveysProvider);
    final authState = ref.watch(authProvider);

    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
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
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.screenWidth * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Header(
                              responsive: responsive,
                              titleFontSize: titleFontSize,
                              descriptionFontSize: descriptionFontSize,
                              title: 'Current Surveys',
                              description:
                                  'Discover and browse surveys shared by the community.',
                            ),
                            const SizedBox(height: 32),
                            surveysAsync.when(
                              data: (surveys) => surveys.isEmpty
                                  ? const Center(
                                      child: Text('No surveys available'))
                                  : Column(
                                      children: surveys
                                          .map((survey) => SurveyCard(
                                                survey: survey,
                                                userId: user.uid,
                                                categoryName: survey.categoryName,
                                                onSurveyCompleted: _refreshSurveys,
                                              ))
                                          .toList(),
                                    ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
