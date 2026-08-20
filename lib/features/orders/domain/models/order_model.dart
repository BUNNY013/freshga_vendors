import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final double totalAmount;
  final double subTotal;
  final double deliveryFee;
  final double taxes;
  final double platformFee;
  final String paymentStatus;
  final String deliveryAddress;
  final String customerPhone;
  final String orderStatus; // 'New', 'Accepted', 'Packed', 'Shipped', 'Delivered', 'Declined'
  final String paymentMethod; // 'Online', 'COD'
  final String payoutStatus; // 'pending', 'paid'
  
  // Tracking & Lifecycle
  final String shippingProvider;
  final String trackingId;
  final String trackingLink;
  final String rejectionReason;
  final List<Map<String, dynamic>> timeline;
  final bool isRated;
  final bool isIssueReported;
  final String issueStatus;
  final String issueId;
  
  // SLAs
  final DateTime expiresAt;
  final DateTime maxDispatchDate;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    this.subTotal = 0.0,
    this.deliveryFee = 0.0,
    this.taxes = 0.0,
    this.platformFee = 0.0,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.customerPhone = '',
    required this.orderStatus,
    this.paymentMethod = 'Online',
    this.payoutStatus = 'pending',
    this.shippingProvider = '',
    this.trackingId = '',
    this.trackingLink = '',
    this.rejectionReason = '',
    this.timeline = const [],
    this.isRated = false,
    this.isIssueReported = false,
    this.issueStatus = '',
    this.issueId = '',
    required this.expiresAt,
    required this.maxDispatchDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? 'Customer',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      subTotal: (json['subTotal'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      taxes: (json['taxes'] ?? 0.0).toDouble(),
      platformFee: (json['platformFee'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      deliveryAddress: json['deliveryAddress'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      orderStatus: json['orderStatus'] ?? 'New',
      paymentMethod: json['paymentMethod'] ?? 'Online',
      payoutStatus: json['payoutStatus'] ?? 'pending',
      shippingProvider: json['shippingProvider'] ?? '',
      trackingId: json['trackingId'] ?? '',
      trackingLink: json['trackingLink'] ?? '',
      rejectionReason: json['rejectionReason'] ?? '',
      timeline: json['timeline'] != null 
          ? List<Map<String, dynamic>>.from(json['timeline']) 
          : [],
      isRated: json['isRated'] ?? false,
      isIssueReported: json['isIssueReported'] ?? false,
      issueStatus: json['issueStatus'] ?? '',
      issueId: json['issueId'] ?? '',
      expiresAt: json['expiresAt'] != null ? (json['expiresAt'] is Timestamp ? (json['expiresAt'] as Timestamp).toDate() : DateTime.parse(json['expiresAt'].toString())) : DateTime.now().add(const Duration(hours: 24)),
      maxDispatchDate: json['maxDispatchDate'] != null ? (json['maxDispatchDate'] is Timestamp ? (json['maxDispatchDate'] as Timestamp).toDate() : DateTime.parse(json['maxDispatchDate'].toString())) : DateTime.now().add(const Duration(days: 2)),
      createdAt: json['createdAt'] != null ? (json['createdAt'] is Timestamp ? (json['createdAt'] as Timestamp).toDate() : DateTime.parse(json['createdAt'].toString())) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] is Timestamp ? (json['updatedAt'] as Timestamp).toDate() : DateTime.parse(json['updatedAt'].toString())) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'storeId': storeId,
      'storeName': storeName,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'subTotal': subTotal,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'platformFee': platformFee,
      'paymentStatus': paymentStatus,
      'deliveryAddress': deliveryAddress,
      'customerPhone': customerPhone,
      'orderStatus': orderStatus,
      'paymentMethod': paymentMethod,
      'payoutStatus': payoutStatus,
      'shippingProvider': shippingProvider,
      'trackingId': trackingId,
      'trackingLink': trackingLink,
      'rejectionReason': rejectionReason,
      'timeline': timeline,
      'isRated': isRated,
      'isIssueReported': isIssueReported,
      'issueStatus': issueStatus,
      'issueId': issueId,
      'expiresAt': expiresAt.toIso8601String(),
      'maxDispatchDate': maxDispatchDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? storeId,
    String? storeName,
    String? customerId,
    String? customerName,
    List<OrderItem>? items,
    double? totalAmount,
    double? subTotal,
    double? deliveryFee,
    double? taxes,
    double? platformFee,
    String? paymentStatus,
    String? deliveryAddress,
    String? customerPhone,
    String? orderStatus,
    String? paymentMethod,
    String? payoutStatus,
    String? shippingProvider,
    String? trackingId,
    String? trackingLink,
    String? rejectionReason,
    List<Map<String, dynamic>>? timeline,
    DateTime? expiresAt,
    DateTime? maxDispatchDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      subTotal: subTotal ?? this.subTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxes: taxes ?? this.taxes,
      platformFee: platformFee ?? this.platformFee,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      shippingProvider: shippingProvider ?? this.shippingProvider,
      trackingId: trackingId ?? this.trackingId,
      trackingLink: trackingLink ?? this.trackingLink,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      timeline: timeline ?? this.timeline,
      expiresAt: expiresAt ?? this.expiresAt,
      maxDispatchDate: maxDispatchDate ?? this.maxDispatchDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String variantLabel;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    this.imageUrl = '',
    this.variantLabel = '',
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      variantLabel: json['variantLabel'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'variantLabel': variantLabel,
      'quantity': quantity,
      'price': price,
    };
  }
}
