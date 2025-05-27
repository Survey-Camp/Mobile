import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:survey_camp/core/models/category_model.dart';
import 'package:survey_camp/shared/theme/category_colors.dart';
// import 'package:survey_camp/shared/theme/theme.dart';

class CategorySelectionDialog extends StatefulWidget {
  const CategorySelectionDialog({Key? key}) : super(key: key);

  @override
  State<CategorySelectionDialog> createState() => _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  final List<CategoryModel> categories = [
    CategoryModel(
      id: 'it',
      name: 'Information Technology',
    ),
    CategoryModel(
      id: 'agriculture',
      name: 'Agriculture',
    ),
    CategoryModel(
      id: 'automobile',
      name: 'Automobile',
    ),
    CategoryModel(
      id: 'healthcare',
      name: 'Healthcare',
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
    ),
    CategoryModel(
      id: 'environment',
      name: 'Environment',
    ),
    CategoryModel(
      id: 'business',
      name: 'Business/Marketing',
    ),
    CategoryModel(
      id: 'social',
      name: 'Social Science',
    ),
  ];

@override
Widget build(BuildContext context) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 8,
    backgroundColor: Colors.white,
    child: Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Your Interests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose categories that interest you to personalize your survey experience',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 1.2, // Adjusted for better text fit
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return AnimatedCategoryTile(
                    category: categories[index],
                    onToggle: (selected) {
                      setState(() {
                        categories[index].isSelected = selected;
                      });
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SafeArea(
            child: ElevatedButton(
              onPressed: () => _saveCategories(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _saveCategories(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final selectedCategories = categories
            .where((category) => category.isSelected)
            .map((category) => category.id)
            .toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'favoriteCategories': selectedCategories,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error saving categories: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save categories. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class AnimatedCategoryTile extends StatelessWidget {
  final CategoryModel category;
  final Function(bool) onToggle;

  const AnimatedCategoryTile({
    Key? key,
    required this.category,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = CategoryColors.getPrimaryColor(category.id);
    final lightColor = CategoryColors.getLightColor(category.id);
    final darkColor = CategoryColors.getDarkColor(category.id);

    return GestureDetector(
      onTap: () => onToggle(!category.isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: category.isSelected ? lightColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: category.isSelected ? darkColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: category.isSelected 
                  ? darkColor.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 8,
              top: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: category.isSelected 
                        ? darkColor 
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: category.isSelected 
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getCategoryIcon(category.id),
                    color: category.isSelected ? darkColor : primaryColor,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: category.isSelected ? darkColor : Colors.black87,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'it':
        return Icons.computer;
      case 'agriculture':
        return Icons.grass;
      case 'automobile':
        return Icons.directions_car;
      case 'healthcare':
        return Icons.healing;
      case 'education':
        return Icons.school;
      case 'environment':
        return Icons.eco;
      case 'business':
        return Icons.business;
      case 'social':
        return Icons.people;
      default:
        return Icons.category;
    }
  }
}