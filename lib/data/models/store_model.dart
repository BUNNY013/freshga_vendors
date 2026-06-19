class StoreModel {
  final String storeId;
  final String ownerId;
  
  final String storeName;
  final String storeSlug;
  final String description;
  
  final String logo;
  final String banner;
  
  final String instagramLink;
  final String youtubeLink;
  final String facebookLink;
  
  final List<String> categories;
  
  final int followers;
  final int likesCount;
  final int productsCount;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  
  final bool verified;
  final bool isFeatured;
  final bool isActive;
  
  final String dispatchTime;
  
  // Location
  final String city;
  final String state;
  final String country;
  final String pincode;
  
  final String createdAt;
  final String updatedAt;

  StoreModel({
    required this.storeId,
    required this.ownerId,
    required this.storeName,
    required this.storeSlug,
    required this.description,
    required this.logo,
    required this.banner,
    required this.instagramLink,
    required this.youtubeLink,
    required this.facebookLink,
    required this.categories,
    required this.followers,
    required this.likesCount,
    required this.productsCount,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.verified,
    required this.isFeatured,
    required this.isActive,
    required this.dispatchTime,
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      storeId: json['storeId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      storeName: json['storeName'] ?? '',
      storeSlug: json['storeSlug'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'] ?? '',
      banner: json['banner'] ?? '',
      instagramLink: json['instagramLink'] ?? '',
      youtubeLink: json['youtubeLink'] ?? '',
      facebookLink: json['facebookLink'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      followers: json['followers'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      productsCount: json['productsCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      verified: json['verified'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
      dispatchTime: json['dispatchTime'] ?? '24 hours',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'ownerId': ownerId,
      'storeName': storeName,
      'storeSlug': storeSlug,
      'description': description,
      'logo': logo,
      'banner': banner,
      'instagramLink': instagramLink,
      'youtubeLink': youtubeLink,
      'facebookLink': facebookLink,
      'categories': categories,
      'followers': followers,
      'likesCount': likesCount,
      'productsCount': productsCount,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'verified': verified,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'dispatchTime': dispatchTime,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  StoreModel copyWith({
    String? storeId,
    String? ownerId,
    String? storeName,
    String? storeSlug,
    String? description,
    String? logo,
    String? banner,
    String? instagramLink,
    String? youtubeLink,
    String? facebookLink,
    List<String>? categories,
    int? followers,
    int? likesCount,
    int? productsCount,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    bool? verified,
    bool? isFeatured,
    bool? isActive,
    String? dispatchTime,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? createdAt,
    String? updatedAt,
  }) {
    return StoreModel(
      storeId: storeId ?? this.storeId,
      ownerId: ownerId ?? this.ownerId,
      storeName: storeName ?? this.storeName,
      storeSlug: storeSlug ?? this.storeSlug,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      instagramLink: instagramLink ?? this.instagramLink,
      youtubeLink: youtubeLink ?? this.youtubeLink,
      facebookLink: facebookLink ?? this.facebookLink,
      categories: categories ?? this.categories,
      followers: followers ?? this.followers,
      likesCount: likesCount ?? this.likesCount,
      productsCount: productsCount ?? this.productsCount,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      verified: verified ?? this.verified,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
