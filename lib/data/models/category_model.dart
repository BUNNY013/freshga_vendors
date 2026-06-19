class CategoryModel {
  final String categoryId;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;

  CategoryModel({
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] is num ? (json['sortOrder'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}
