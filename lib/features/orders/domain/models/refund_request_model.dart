import 'package:cloud_firestore/cloud_firestore.dart';

class RefundItemModel {
  final String productId;
  final String productName;
  final String variantLabel;
  final double price;
  final int quantity;

  RefundItemModel({
    required this.productId,
    required this.productName,
    required this.variantLabel,
    required this.price,
    required this.quantity,
  });

  factory RefundItemModel.fromJson(Map<String, dynamic> json) {
    return RefundItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      variantLabel: json['variantLabel'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'variantLabel': variantLabel,
      'price': price,
      'quantity': quantity,
    };
  }
}

class RefundRequestModel {
  final String requestId;
  final String orderId;
  final String storeId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<RefundItemModel> items;
  final String reason;
  final String description;
  final List<String> imageUrls;
  final String status; // 'Pending Vendor', 'Approved by Vendor', 'Disputed', 'Refund Processed', 'Rejected'
  final double refundAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  RefundRequestModel({
    required this.requestId,
    required this.orderId,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.reason,
    required this.description,
    required this.imageUrls,
    required this.status,
    required this.refundAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json, String id) {
    return RefundRequestModel(
      requestId: id,
      orderId: json['orderId'] ?? '',
      storeId: json['storeId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? 'Customer',
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => RefundItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      status: json['status'] ?? 'Pending Vendor',
      refundAmount: (json['refundAmount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null ? (json['createdAt'] is Timestamp ? (json['createdAt'] as Timestamp).toDate() : DateTime.parse(json['createdAt'].toString())) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] is Timestamp ? (json['updatedAt'] as Timestamp).toDate() : DateTime.parse(json['updatedAt'].toString())) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'storeId': storeId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'reason': reason,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'refundAmount': refundAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
