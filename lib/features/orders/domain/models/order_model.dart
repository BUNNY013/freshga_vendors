class OrderModel {
  final String orderId;
  final String storeId;
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
  
  // Tracking & Lifecycle
  final String shippingProvider;
  final String trackingId;
  final String trackingLink;
  final String rejectionReason;
  final List<Map<String, dynamic>> timeline;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.storeId,
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
    this.shippingProvider = '',
    this.trackingId = '',
    this.trackingLink = '',
    this.rejectionReason = '',
    this.timeline = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      storeId: json['storeId'] ?? '',
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
      shippingProvider: json['shippingProvider'] ?? '',
      trackingId: json['trackingId'] ?? '',
      trackingLink: json['trackingLink'] ?? '',
      rejectionReason: json['rejectionReason'] ?? '',
      timeline: json['timeline'] != null 
          ? List<Map<String, dynamic>>.from(json['timeline']) 
          : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'storeId': storeId,
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
      'shippingProvider': shippingProvider,
      'trackingId': trackingId,
      'trackingLink': trackingLink,
      'rejectionReason': rejectionReason,
      'timeline': timeline,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? storeId,
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
    String? shippingProvider,
    String? trackingId,
    String? trackingLink,
    String? rejectionReason,
    List<Map<String, dynamic>>? timeline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      storeId: storeId ?? this.storeId,
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
      shippingProvider: shippingProvider ?? this.shippingProvider,
      trackingId: trackingId ?? this.trackingId,
      trackingLink: trackingLink ?? this.trackingLink,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }
}
