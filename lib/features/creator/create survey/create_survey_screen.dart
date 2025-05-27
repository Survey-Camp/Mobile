import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/core/models/category_model.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:survey_camp/features/creator/create_survey_question/create_survey_question.dart';
import 'package:survey_camp/features/creator/generate_question/generate_questions.dart';
import 'package:survey_camp/features/creator/create_survey/widgets/insufficient_points_dialog.dart';

class CreateSurveyScreen extends ConsumerStatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  ConsumerState<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends ConsumerState<CreateSurveyScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController customCategoryController =
      TextEditingController();

  String? selectedCategory;
  List<CategoryModel> categories = [];
  bool isLoading = true;
  bool showCustomCategory = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _checkAndShowInsufficientPoints();
  });
}

// Add new method to handle points check and dialog
Future<void> _checkAndShowInsufficientPoints() async {
  if (!mounted) return;
  
  if (!await _checkUserPoints(showDialog: false)) {
    await showInsufficientPointsDialog(context);
  }
}

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    customCategoryController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        categories = snapshot.docs
            .map(
                (doc) => CategoryModel(id: doc.id, name: doc['name'] as String))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> createSurvey({
    required String title,
    required String description,
    required String categoryName,
    required String? categoryId,
  }) async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to create a survey')));
        return null;
      }

      String finalCategoryId = categoryId ?? '';
      if (categoryId == null && categoryName.isNotEmpty) {
        final categoryDoc =
            await FirebaseFirestore.instance.collection('categories').add({
          'name': categoryName,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
        });
        finalCategoryId = categoryDoc.id;
      }

      final surveyDoc =
          await FirebaseFirestore.instance.collection('surveys').add({
        'title': title,
        'description': description,
        'categoryId': finalCategoryId,
        'categoryName': categoryName,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'draft',
      });

      return surveyDoc.id;
    } catch (e) {
      print('Error creating survey: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating survey: $e')));
      return null;
    }
  }

Future<void> handleSurveyCreation({bool isAIGenerated = false}) async {
  // First check if user has enough points
  if (!await _checkUserPoints()) {
    return;
  }

  if (titleController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a survey title')));
    return;
  }

  if (selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')));
    return;
  }

  if (selectedCategory == "custom" && customCategoryController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')));
    return;
  }

  final category = selectedCategory == "custom"
      ? customCategoryController.text.trim()
      : selectedCategory ?? '';
  final categoryId = categories
      .firstWhere((c) => c.name == selectedCategory,
          orElse: () => CategoryModel(id: '', name: ''))
      .id;

  try {
    final surveyId = await createSurvey(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      categoryName: category,
      categoryId: selectedCategory == "custom" ? null : categoryId,
    );

    if (surveyId != null) {
      // Deduct points
      final user = ref.read(authProvider).value;
      if (user != null) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userDoc = await transaction.get(userRef);
          final currentPoints = (userDoc.data()?['totalPoints'] ?? 0) as int;
          transaction.update(userRef, {
            'totalPoints': currentPoints - 150,
          });
        });
      }

      if (context.mounted) {
        if (isAIGenerated) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => GenerateQuestionScreen(
                    category: category,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    surveyId: surveyId, // Pass the surveyId here
                  )));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CreateSurveyQuestionScreen(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    category: category,
                    surveyId: surveyId,
                  )));
        }
      }
    }
  } catch (e) {
    print('Error in handleSurveyCreation: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating survey: $e'),
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

 Future<bool> _checkUserPoints({bool showDialog = true}) async {
  final user = ref.read(authProvider).value;
  if (user != null) {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final totalPoints = (userDoc.data()?['totalPoints'] ?? 0) as int;
      if (totalPoints < 150) {
        if (!mounted) return false;
        if (showDialog) {
          await showInsufficientPointsDialog(context);
        }
        return false;
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error checking points. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return false;
    }
  }
  return false;
}

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        return _buildMainContent();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildMainContent() {
    final responsive = Responsive(context);
    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;
    double iconSize = responsive.screenWidth * 0.06;
    double padding = responsive.screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: responsive.screenWidth * 0.05,
                vertical: responsive.screenHeight * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      )),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: responsive.screenWidth * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create a survey',
                          style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'Design your survey and gather valuable insights effortlessly.',
                          style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: Colors.grey[600])),
                      const SizedBox(height: 32),
                      _buildMainContainer(descriptionFontSize),
                      const SizedBox(height: 24),
                      _buildTipsSection(descriptionFontSize),
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

  Widget _buildMainContainer(double descriptionFontSize) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputSection("Survey Title", "Enter your survey title",
              titleController, descriptionFontSize,
              maxLines: 1),
          const SizedBox(height: 24),
          _buildInputSection(
              "Survey Description",
              "Provide a brief description of the survey",
              descriptionController,
              descriptionFontSize,
              maxLines: 3),
          const SizedBox(height: 24),
          _buildCategoryDropdown(descriptionFontSize),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(double descriptionFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Category",
            style: TextStyle(
                fontSize: descriptionFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: AppPalettes.lightGray,
                borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                hint: const Text("Select a category"),
                items: [
                  ...categories.map((category) => DropdownMenuItem(
                      value: category.name, child: Text(category.name))),
                  const DropdownMenuItem(
                      value: "custom", child: Text("Create New Category")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                    showCustomCategory = value == "custom";
                    if (value != "custom") {
                      customCategoryController.clear();
                    }
                  });
                },
              ),
            ),
          ),
        if (showCustomCategory) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: customCategoryController,
            decoration: InputDecoration(
              hintText: "Enter new category name",
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: AppPalettes.lightGray,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
            context,
            'Create Survey Manually',
            Icons.edit_note_rounded,
            () => handleSurveyCreation(isAIGenerated: false)),
        const SizedBox(height: 12),
        _buildActionButton(
            context,
            'Generate with AI',
            Icons.auto_awesome_rounded,
            () => handleSurveyCreation(isAIGenerated: true),
            isPrimary: true),
      ],
    );
  }

  Widget _buildTipsSection(double descriptionFontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                'Try AI generation for smart, context-aware survey questions based on your goals',
                style: TextStyle(
                    fontSize: descriptionFontSize, color: Colors.blue[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(String label, String hint,
      TextEditingController controller, double fontSize,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: AppPalettes.lightGray,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback onPressed,
      {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isPrimary ? AppPalettes.primary : Colors.grey[100],
          foregroundColor: isPrimary ? Colors.black : Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}