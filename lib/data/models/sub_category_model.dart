class SubCategoryModel {
  final String subCategoryId;
  final String categoryId;
  final String name;
  final bool isActive;
  final int sortOrder;

  SubCategoryModel({
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      subCategoryId: json['subCategoryId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
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
