// class CategoryModel {
//   final String id;
//   final String name;

//   CategoryModel({
//     required this.id,
//     required this.name,
//   });
// }

class CategoryModel {
  final String id;
  final String name;
  bool isSelected;

  CategoryModel({
    required this.id,
    required this.name,
    this.isSelected = false,
  });
}