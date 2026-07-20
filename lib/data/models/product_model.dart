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
  final String categoryName;
  final List<String> subCategoryIds;

  final double price;
  final double originalPrice;
  final String weight;
  
  final String shelfLife;
  final String dispatchTime;
  final String storageInstructions;
  final bool showStockToCustomers;
  
  final String status; // 'Draft', 'Submitted', 'Under Review', 'Approved', 'Live', 'Live + Draft Changes', 'Live + Update Pending', 'Changes Required', 'Unavailable', 'Hidden'
  final String adminFeedback; // Rejection reason if Changes Required
  final bool isStoreVerified;

  final Map<String, dynamic>? pendingUpdate; // Legacy field (keeping for compatibility)
  final String? updateAdminFeedback; // Legacy field
  final Map<String, dynamic>? reviewFeedback;

  // Lifecycle V2 fields
  final Map<String, dynamic>? draftVersion;
  final Map<String, dynamic>? pendingReviewVersion;
  final List<String> requiredFixes;
  final String? lastApprovedAt;
  final String? lastSubmittedAt;
  final int versionNumber;

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
  
  final String state;
  final bool canSellPanIndia;

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
    required this.categoryName,
    required this.subCategoryIds,
    required this.price,
    required this.originalPrice,
    required this.weight,
    required this.shelfLife,
    required this.dispatchTime,
    required this.storageInstructions,
    required this.showStockToCustomers,
    required this.status,
    required this.adminFeedback,
    required this.isStoreVerified,
    this.pendingUpdate,
    this.updateAdminFeedback,
    this.reviewFeedback,
    this.draftVersion,
    this.pendingReviewVersion,
    this.requiredFixes = const [],
    this.lastApprovedAt,
    this.lastSubmittedAt,
    this.versionNumber = 1,
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
    this.state = '',
    this.canSellPanIndia = false,
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
      categoryName: json['categoryName'] ?? '',
      subCategoryIds: List<String>.from(json['subCategoryIds'] ?? []),
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      weight: json['weight'] ?? '',
      shelfLife: json['shelfLife'] ?? '',
      dispatchTime: json['dispatchTime'] ?? '',
      storageInstructions: json['storageInstructions'] ?? '',
      showStockToCustomers: json['showStockToCustomers'] ?? false,
      status: json['status'] ?? 'Draft',
      adminFeedback: json['adminFeedback'] as String? ?? '',
      isStoreVerified: json['isStoreVerified'] as bool? ?? false,
      pendingUpdate: json['pendingUpdate'] as Map<String, dynamic>?,
      updateAdminFeedback: json['updateAdminFeedback'] as String?,
      reviewFeedback: json['reviewFeedback'] as Map<String, dynamic>?,
      draftVersion: json['draftVersion'] as Map<String, dynamic>?,
      pendingReviewVersion: json['pendingReviewVersion'] as Map<String, dynamic>?,
      requiredFixes: List<String>.from(json['requiredFixes'] ?? []),
      lastApprovedAt: json['lastApprovedAt'] as String?,
      lastSubmittedAt: json['lastSubmittedAt'] as String?,
      versionNumber: json['versionNumber'] as int? ?? 1,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
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
      isTrending: json['isTrending'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      state: json['state'] ?? '',
      canSellPanIndia: json['canSellPanIndia'] ?? false,
      searchKeywords: (json['searchKeywords'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
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
      'categoryName': categoryName,
      'subCategoryIds': subCategoryIds,
      'price': price,
      'originalPrice': originalPrice,
      'weight': weight,
      'shelfLife': shelfLife,
      'dispatchTime': dispatchTime,
      'storageInstructions': storageInstructions,
      'showStockToCustomers': showStockToCustomers,
      'status': status,
      'adminFeedback': adminFeedback,
      'isStoreVerified': isStoreVerified,
      'pendingUpdate': pendingUpdate,
      'updateAdminFeedback': updateAdminFeedback,
      'reviewFeedback': reviewFeedback,
      'draftVersion': draftVersion,
      'pendingReviewVersion': pendingReviewVersion,
      'requiredFixes': requiredFixes,
      'lastApprovedAt': lastApprovedAt,
      'lastSubmittedAt': lastSubmittedAt,
      'versionNumber': versionNumber,
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
      'state': state,
      'canSellPanIndia': canSellPanIndia,
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
    String? categoryName,
    List<String>? subCategoryIds,
    double? price,
    double? originalPrice,
    String? weight,
    String? shelfLife,
    String? dispatchTime,
    String? storageInstructions,
    bool? showStockToCustomers,
    String? status,
    String? adminFeedback,
    bool? isStoreVerified,
    Map<String, dynamic>? pendingUpdate,
    String? updateAdminFeedback,
    Map<String, dynamic>? reviewFeedback,
    Map<String, dynamic>? draftVersion,
    Map<String, dynamic>? pendingReviewVersion,
    List<String>? requiredFixes,
    String? lastApprovedAt,
    String? lastSubmittedAt,
    int? versionNumber,
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
    String? state,
    bool? canSellPanIndia,
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
      categoryName: categoryName ?? this.categoryName,
      subCategoryIds: subCategoryIds ?? this.subCategoryIds,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      weight: weight ?? this.weight,
      shelfLife: shelfLife ?? this.shelfLife,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      showStockToCustomers: showStockToCustomers ?? this.showStockToCustomers,
      status: status ?? this.status,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      isStoreVerified: isStoreVerified ?? this.isStoreVerified,
      pendingUpdate: pendingUpdate ?? this.pendingUpdate,
      updateAdminFeedback: updateAdminFeedback ?? this.updateAdminFeedback,
      reviewFeedback: reviewFeedback ?? this.reviewFeedback,
      draftVersion: draftVersion ?? this.draftVersion,
      pendingReviewVersion: pendingReviewVersion ?? this.pendingReviewVersion,
      requiredFixes: requiredFixes ?? this.requiredFixes,
      lastApprovedAt: lastApprovedAt ?? this.lastApprovedAt,
      lastSubmittedAt: lastSubmittedAt ?? this.lastSubmittedAt,
      versionNumber: versionNumber ?? this.versionNumber,
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
      state: state ?? this.state,
      canSellPanIndia: canSellPanIndia ?? this.canSellPanIndia,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Merges draft fields into the product model for the UI editors.
  ProductModel applyDraftUpdates() {
    final Map<String, dynamic> sourceMap = draftVersion ?? pendingUpdate ?? {};
    if (sourceMap.isEmpty) return this;
    
    final currentJson = toJson();
    currentJson.addAll(Map<String, dynamic>.from(sourceMap));
    
    return ProductModel.fromJson(currentJson);
  }

  /// Legacy support
  ProductModel applyPendingUpdates() {
    final Map<String, dynamic> sourceMap = pendingReviewVersion ?? pendingUpdate ?? {};
    if (sourceMap.isEmpty) return this;
    
    final currentJson = toJson();
    currentJson.addAll(Map<String, dynamic>.from(sourceMap));
    
    return ProductModel.fromJson(currentJson);
  }
}
