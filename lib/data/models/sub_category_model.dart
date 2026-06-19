class SubCategoryModel {
  final String subCategoryId;
  final String categoryId;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;

  SubCategoryModel({
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    this.imageUrl = '',
    required this.isActive,
    required this.sortOrder,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      subCategoryId: json['subCategoryId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] is num ? (json['sortOrder'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subCategoryId': subCategoryId,
      'categoryId': categoryId,
      'name': name,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}
