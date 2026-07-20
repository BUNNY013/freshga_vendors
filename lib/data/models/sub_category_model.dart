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
      subCategoryId: json['subCategoryId']?.toString() ?? json['slug']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: (json['image'] != null && json['image']['url'] != null) ? json['image']['url'].toString() : (json['imageUrl']?.toString() ?? ''),
      isActive: json['status']?.toString().toLowerCase() == 'active' || json['isActive'] == true || json['isActive']?.toString().toLowerCase() == 'true',
      sortOrder: (json['displayIndex'] as num?)?.toInt() ?? (json['sortOrder'] as num?)?.toInt() ?? 0,
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
