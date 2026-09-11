import 'package:cloud_firestore/cloud_firestore.dart';

class VendorSubscriptionModel {
  final String storeId;
  final String status; // 'trialing', 'active', 'grace_period', 'expired'
  final DateTime trialEndsAt;
  final DateTime? currentPeriodEnd;
  final DateTime? customGracePeriodEnd;

  VendorSubscriptionModel({
    required this.storeId,
    required this.status,
    required this.trialEndsAt,
    this.currentPeriodEnd,
    this.customGracePeriodEnd,
  });

  factory VendorSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return VendorSubscriptionModel(
      storeId: json['storeId'] ?? '',
      status: json['status'] ?? 'expired',
      trialEndsAt: json['trialEndsAt'] != null 
          ? (json['trialEndsAt'] is Timestamp 
              ? (json['trialEndsAt'] as Timestamp).toDate() 
              : DateTime.parse(json['trialEndsAt'].toString())) 
          : DateTime.now().subtract(const Duration(days: 1)),
      currentPeriodEnd: json['currentPeriodEnd'] != null 
          ? (json['currentPeriodEnd'] is Timestamp 
              ? (json['currentPeriodEnd'] as Timestamp).toDate() 
              : DateTime.parse(json['currentPeriodEnd'].toString())) 
          : null,
      customGracePeriodEnd: json['customGracePeriodEnd'] != null 
          ? (json['customGracePeriodEnd'] is Timestamp 
              ? (json['customGracePeriodEnd'] as Timestamp).toDate() 
              : DateTime.parse(json['customGracePeriodEnd'].toString())) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'status': status,
      'trialEndsAt': trialEndsAt.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      if (customGracePeriodEnd != null) 'customGracePeriodEnd': customGracePeriodEnd?.toIso8601String(),
    };
  }

  bool get isTrialActive => 
      status == 'trialing' && DateTime.now().isBefore(trialEndsAt);

  // Checks if the paid subscription is currently active (not expired)
  bool get isPaidActive => 
      status == 'active' && currentPeriodEnd != null && DateTime.now().isBefore(currentPeriodEnd!);
      
  // Grace period logic: If the customGracePeriodEnd is set, use it. Otherwise default to currentPeriodEnd + 3 days
  bool get isInGracePeriod {
    if (currentPeriodEnd == null) return false;
    final graceEndsAt = customGracePeriodEnd ?? currentPeriodEnd!.add(const Duration(days: 3));
    return DateTime.now().isAfter(currentPeriodEnd!) && DateTime.now().isBefore(graceEndsAt);
  }

  // The store is considered completely offline if it's not trialing, not active, and past the grace period.
  bool get isCompletelyExpired {
    if (isTrialActive || isPaidActive || isInGracePeriod) return false;
    return true; 
  }
  
  // The store is visible to customers if it's trialing, active, or in grace period
  bool get isVisibleToCustomers => !isCompletelyExpired;
}
