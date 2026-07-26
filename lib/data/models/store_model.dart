import 'package:cloud_firestore/cloud_firestore.dart';
import 'delivery_area_model.dart';

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
  final String whatsappNumber;
  
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
  final String status;
  bool get isSuspended => status.toLowerCase() == 'suspended';
  final bool canSellPanIndia;
  
  // Tax Info
  final String taxRegistrationType; // 'GSTIN' or 'EnrolmentNumber'
  final String taxNumber;
  
  // Location
  final String businessAddress;
  final String village;
  final String city;
  final String district;
  final String state;
  final String country;
  final String pincode;
  
  // Shipping
  final Map<String, dynamic> shippingConfig;
  final List<DeliveryAreaModel> deliveryAreas;
  
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
    required this.whatsappNumber,
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
    this.status = 'Active',
    this.canSellPanIndia = false,
    this.taxRegistrationType = '',
    this.taxNumber = '',
    this.businessAddress = '',
    this.village = '',
    this.city = '',
    this.district = '',
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
      youtubeLink: json['youtubeLink'] ?? '',
      facebookLink: json['facebookLink'] ?? '',
      whatsappNumber: json['whatsappNumber'] ?? '',
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
      status: json['status'] ?? 'Active',
      canSellPanIndia: json['canSellPanIndia'] ?? false,
      taxRegistrationType: json['taxRegistrationType'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      village: json['village'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      shippingConfig: Map<String, dynamic>.from(json['shippingConfig'] ?? {}),
      deliveryAreas: json['deliveryAreas'] != null 
          ? (json['deliveryAreas'] as List).map((e) => DeliveryAreaModel.fromJson(e)).toList() 
          : DeliveryAreaModel.createDefaultAreas(json['state'] ?? '', json['canSellPanIndia'] ?? false),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate().toIso8601String()
              : json['createdAt'].toString())
          : '',
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate().toIso8601String()
              : json['updatedAt'].toString())
          : '',
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
      'whatsappNumber': whatsappNumber,
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
      'status': status,
      'canSellPanIndia': canSellPanIndia,
      'taxRegistrationType': taxRegistrationType,
      'taxNumber': taxNumber,
      'businessAddress': businessAddress,
      'village': village,
      'city': city,
      'district': district,
      'state': state,
      'country': country,
      'pincode': pincode,
      'shippingConfig': shippingConfig,
      'deliveryAreas': deliveryAreas.map((e) => e.toJson()).toList(),
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
    String? whatsappNumber,
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
    String? status,
    bool? canSellPanIndia,
    String? city,
    String? state,
    String? country,
    String? pincode,
    Map<String, dynamic>? shippingConfig,
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
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
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
      status: status ?? this.status,
      canSellPanIndia: canSellPanIndia ?? this.canSellPanIndia,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      shippingConfig: shippingConfig ?? this.shippingConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
