import 'product_variant_model.dart';

class ProductModel {
  final String productId;
  final String storeId;
  final String storeName;

  final String name;
  final String slug;

  final String description;
  final String shortDescription;

  final String categoryId;
  final String subCategoryId;

  final List<String> images;
  final List<ProductVariantModel> variants;

  final List<String> ingredients;
  final List<String> tags;

  final double rating;
  final int totalReviews;
  final int totalOrders;

  final int likes;
  final int wishlistCount;

  final bool isFeatured;
  final bool isTrending;
  final bool isActive;

  final List<String> searchKeywords;

  final String createdAt;
  final String updatedAt;

  ProductModel({
    required this.productId,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.categoryId,
    required this.subCategoryId,
    required this.images,
    required this.variants,
    required this.ingredients,
    required this.tags,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.likes,
    required this.wishlistCount,
    required this.isFeatured,
    required this.isTrending,
    required this.isActive,
    required this.searchKeywords,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] ?? '',
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      categoryId: json['categoryId'] ?? '',
      subCategoryId: json['subCategoryId'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      likes: json['likes'] ?? 0,
      wishlistCount: json['wishlistCount'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isTrending: json['isTrending'] ?? false,
      isActive: json['isActive'] ?? true,
      searchKeywords: List<String>.from(json['searchKeywords'] ?? []),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'storeId': storeId,
      'storeName': storeName,
      'name': name,
      'slug': slug,
      'description': description,
      'shortDescription': shortDescription,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'images': images,
      'variants': variants.map((v) => v.toJson()).toList(),
      'ingredients': ingredients,
      'tags': tags,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'likes': likes,
      'wishlistCount': wishlistCount,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'isActive': isActive,
      'searchKeywords': searchKeywords,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? storeId,
    String? storeName,
    String? name,
    String? slug,
    String? description,
    String? shortDescription,
    String? categoryId,
    String? subCategoryId,
    List<String>? images,
    List<ProductVariantModel>? variants,
    List<String>? ingredients,
    List<String>? tags,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    int? likes,
    int? wishlistCount,
    bool? isFeatured,
    bool? isTrending,
    bool? isActive,
    List<String>? searchKeywords,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      ingredients: ingredients ?? this.ingredients,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      likes: likes ?? this.likes,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isTrending: isTrending ?? this.isTrending,
      isActive: isActive ?? this.isActive,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
