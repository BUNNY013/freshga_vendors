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
  
  // Status: Draft, Published, Out of Stock, Hidden
  final String status;
  
  final int likesCount;
  
  final String createdAt;
  final String updatedAt;

  ProductModel({
    required this.productId,
    required this.storeId,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.weight,
    required this.shelfLife,
    required this.ingredients,
    required this.category,
    required this.subCategory,
    required this.tags,
    required this.stock,
    required this.images,
    required this.status,
    required this.likesCount,
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
      likesCount: json['likesCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
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
      'likesCount': likesCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? storeId,
    String? name,
    String? shortDescription,
    String? description,
    double? price,
    double? discountPrice,
    String? weight,
    String? shelfLife,
    List<String>? ingredients,
    String? category,
    String? subCategory,
    List<String>? tags,
    int? stock,
    List<String>? images,
    String? status,
    int? likesCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      weight: weight ?? this.weight,
      shelfLife: shelfLife ?? this.shelfLife,
      ingredients: ingredients ?? this.ingredients,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      tags: tags ?? this.tags,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
