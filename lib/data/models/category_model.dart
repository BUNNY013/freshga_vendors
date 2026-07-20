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
      categoryId: json['categoryId']?.toString() ?? json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: (json['image'] != null && json['image']['url'] != null) ? json['image']['url'].toString() : (json['imageUrl']?.toString() ?? ''),
      isActive: json['status']?.toString().toLowerCase() == 'active' || json['isActive'] == true || json['isActive']?.toString().toLowerCase() == 'true',
      sortOrder: (json['displayIndex'] as num?)?.toInt() ?? (json['sortOrder'] as num?)?.toInt() ?? 0,
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
