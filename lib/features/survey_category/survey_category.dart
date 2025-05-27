import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/features/survey_category/SurveyCategoryDetailScreen.dart';
import 'package:survey_camp/shared/widgets/top_bar.dart';
import 'package:survey_camp/shared/theme/category_colors.dart';
import 'services/survey_category_service.dart';

class SurveyCategoryScreen extends StatefulWidget {
  const SurveyCategoryScreen({super.key});

  @override
  State<SurveyCategoryScreen> createState() => _SurveyCategoryScreenState();
}

class _SurveyCategoryScreenState extends State<SurveyCategoryScreen> {
  final SurveyCategoryService _categoryService = SurveyCategoryService();
  Map<String, int> _surveyCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveyCounts();
  }

Future<void> _loadSurveyCounts() async {
  if (!mounted) return;

  try {
    setState(() {
      _isLoading = true;
      _surveyCounts.clear();
    });

    final categories = await _categoryService.getSurveyCategoriesWithCount();

    if (!mounted) return;

    setState(() {
      for (var category in categories) {
        String categoryId = category['categoryId'].toString().toLowerCase();
        int count = category['surveyCount'] as int;
        _surveyCounts[categoryId] = count;
      }
      _isLoading = false;
    });
  } catch (e) {
    print('Error in _loadSurveyCounts: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSurveyCounts();
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.screenWidth * 0.05,
              vertical: responsive.screenHeight * 0.03,
            ),
            child: Column(
              children: [
                const CustomTopBar(),
                const SizedBox(height: 24),
                _buildHeaderSection(titleFontSize, descriptionFontSize),
                const SizedBox(height: 16),
                _buildCategoriesList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double titleFontSize, double descriptionFontSize) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: titleFontSize * 0.33),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Survey Categories',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore various survey categories and select your interest',
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Expanded(
      child: ListView(
        children: [
          _buildSurveyCategory(
            icon: LucideIcons.laptop,
            title: 'Information Technology',
            description: 'Surveys',
            categoryId: 'information technology',
            onTap: () => _navigateToSubcategory(context, 'Information Technology'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.wheat,
            title: 'Agriculture',
            description: 'Surveys',
            categoryId: 'agriculture',
            onTap: () => _navigateToSubcategory(context, 'Agriculture'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.car,
            title: 'Automobile',
            description: 'Surveys',
            categoryId: 'automobile',
            onTap: () => _navigateToSubcategory(context, 'Automobile'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.heartPulse,
            title: 'Healthcare',
            description: 'Surveys',
            categoryId: 'healthcare',
            onTap: () => _navigateToSubcategory(context, 'Healthcare'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.graduationCap,
            title: 'Education',
            description: 'Surveys',
            categoryId: 'education',
            onTap: () => _navigateToSubcategory(context, 'Education'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.trees,
            title: 'Environment',
            description: 'Surveys',
            categoryId: 'environment',
            onTap: () => _navigateToSubcategory(context, 'Environment'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.briefcase,
            title: 'Business/Marketing',
            description: 'Surveys',
            categoryId: 'business',
            onTap: () => _navigateToSubcategory(context, 'Business/Marketing'),
          ),
          const SizedBox(height: 16),
          _buildSurveyCategory(
            icon: LucideIcons.users,
            title: 'Social Science',
            description: 'Surveys',
            categoryId: 'social',
            onTap: () => _navigateToSubcategory(context, 'Social Science'),
          ),
        ],
      ),
    );
  }

  void _navigateToSubcategory(BuildContext context, String mainCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyCategoryDetailScreen(category: mainCategory),
      ),
    );
  }

  Widget _buildSurveyCategory({
    required IconData icon,
    required String title,
    required String description,
    required String categoryId,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CategoryColors.getLightColor(categoryId),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CategoryColors.getLightColor(categoryId),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CategoryColors.getDarkColor(categoryId).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon, 
                size: 24,
                color: CategoryColors.getPrimaryColor(categoryId),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CategoryColors.getDarkColor(categoryId),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: CategoryColors.getDarkColor(categoryId).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: CategoryColors.getPrimaryColor(categoryId),
              size: 20,
            )
          ],
        ),
      ),
    );
  }
}