import '../../../../data/models/delivery_area_model.dart';

class StoreModel {
  final String storeId;
  final String ownerId;
  final String storeName;
  final String storeSlug;
  final String description;
  final String logo;
  final String banner;
  final String instagramLink;
  final String facebookLink;
  final String youtubeLink;
  final List<String> categories;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final int followers;
  final bool verified;
  final bool isFeatured;
  final bool isActive;
  final bool canSellPanIndia;
  final String dispatchTime;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final Map<String, dynamic> shippingConfig;
  final List<DeliveryAreaModel> deliveryAreas;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreModel({
    required this.storeId,
    required this.ownerId,
    required this.storeName,
    required this.storeSlug,
    required this.description,
    required this.logo,
    required this.banner,
    required this.instagramLink,
    this.facebookLink = '',
    this.youtubeLink = '',
    required this.categories,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.followers = 0,
    this.verified = false,
    this.isFeatured = false,
    this.isActive = true,
    this.canSellPanIndia = false,
    required this.dispatchTime,
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
    this.shippingConfig = const {},
    this.deliveryAreas = const [],
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
      facebookLink: json['facebookLink'] ?? '',
      youtubeLink: json['youtubeLink'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      followers: json['followers'] ?? 0,
      verified: json['verified'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
      canSellPanIndia: json['canSellPanIndia'] ?? false,
      dispatchTime: json['dispatchTime'] ?? '24 hours',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      shippingConfig: Map<String, dynamic>.from(json['shippingConfig'] ?? {}),
      deliveryAreas: json['deliveryAreas'] != null && (json['deliveryAreas'] as List).isNotEmpty
          ? (json['deliveryAreas'] as List).map((e) => DeliveryAreaModel.fromJson(e)).toList() 
          : DeliveryAreaModel.createDefaultAreas(json['state'] ?? '', json['canSellPanIndia'] ?? false),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
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
      'facebookLink': facebookLink,
      'youtubeLink': youtubeLink,
      'categories': categories,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'followers': followers,
      'verified': verified,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'canSellPanIndia': canSellPanIndia,
      'dispatchTime': dispatchTime,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'shippingConfig': shippingConfig,
      'deliveryAreas': deliveryAreas.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    String? facebookLink,
    String? youtubeLink,
    List<String>? categories,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    int? followers,
    bool? verified,
    bool? isFeatured,
    bool? isActive,
    bool? canSellPanIndia,
    String? dispatchTime,
    String? city,
    String? state,
    String? country,
    String? pincode,
    Map<String, dynamic>? shippingConfig,
    List<DeliveryAreaModel>? deliveryAreas,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      facebookLink: facebookLink ?? this.facebookLink,
      youtubeLink: youtubeLink ?? this.youtubeLink,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      followers: followers ?? this.followers,
      verified: verified ?? this.verified,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      canSellPanIndia: canSellPanIndia ?? this.canSellPanIndia,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      shippingConfig: shippingConfig ?? this.shippingConfig,
      deliveryAreas: deliveryAreas ?? this.deliveryAreas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
