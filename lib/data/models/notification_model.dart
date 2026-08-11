import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String vendorId;
  final String title;
  final String message;
  final String type; // 'order', 'payout', 'alert', 'system'
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;

  NotificationModel({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String documentId) {
    return NotificationModel(
      id: documentId,
      vendorId: json['vendorId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      relatedId: json['relatedId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? vendorId,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
    );
  }
}
