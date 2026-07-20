class ProductModel {
  final String productId;
  final String storeId;
  final String name;
  final String shortDescription;
  final String description;
  final double price;
  final double discountPrice;
  final String weight;
  final String shelfLife;
  final List<String> ingredients;
  final String category;
  final String subCategory;
  final List<String> tags;
  final int stock;
  final List<String> images;
  final String status; // 'In Stock', 'Out of Stock', 'Draft', 'Published'
  final String state;
  final bool canSellPanIndia;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.productId,
    required this.storeId,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.price,
    this.discountPrice = 0.0,
    required this.weight,
    required this.shelfLife,
    required this.ingredients,
    required this.category,
    this.subCategory = '',
    required this.tags,
    required this.stock,
    required this.images,
    required this.status,
    this.state = '',
    this.canSellPanIndia = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] ?? '',
      storeId: json['storeId'] ?? '',
      name: json['name'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: (json['discountPrice'] ?? 0.0).toDouble(),
      weight: json['weight'] ?? '',
      shelfLife: json['shelfLife'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      stock: json['stock'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? 'Draft',
      state: json['state'] ?? '',
      canSellPanIndia: json['canSellPanIndia'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'storeId': storeId,
      'name': name,
      'shortDescription': shortDescription,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'weight': weight,
      'shelfLife': shelfLife,
      'ingredients': ingredients,
      'category': category,
      'subCategory': subCategory,
      'tags': tags,
      'stock': stock,
      'images': images,
      'status': status,
      'state': state,
      'canSellPanIndia': canSellPanIndia,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
