import 'package:cloud_firestore/cloud_firestore.dart';

class VendorSubscriptionModel {
  final String storeId;
  final String status; // 'trialing', 'active', 'past_due', 'canceled', 'expired'
  final String currentTier; // 'basic', 'growth', 'pro'
  final DateTime trialEndsAt;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final List<String> activeFeatures;

  VendorSubscriptionModel({
    required this.storeId,
    required this.status,
    required this.currentTier,
    required this.trialEndsAt,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.activeFeatures,
  });

  factory VendorSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return VendorSubscriptionModel(
      storeId: json['storeId'] ?? '',
      status: json['status'] ?? 'expired',
      currentTier: json['currentTier'] ?? 'basic',
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
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] ?? false,
      activeFeatures: List<String>.from(json['activeFeatures'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'status': status,
      'currentTier': currentTier,
      'trialEndsAt': trialEndsAt.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'activeFeatures': activeFeatures,
    };
  }

  bool get isTrialActive => 
      status == 'trialing' && DateTime.now().isBefore(trialEndsAt);

  bool get isSubscriptionActive => 
      (status == 'active' && currentPeriodEnd != null && DateTime.now().isBefore(currentPeriodEnd!)) || isTrialActive;
      
  bool get hasAdvancedAnalytics => currentTier == 'growth' || currentTier == 'pro';
  bool get hasPromotionalBanners => currentTier == 'pro';
  bool get hasTopSearchAppearance => currentTier == 'pro';
  bool get hasVerifiedBadge => currentTier == 'growth' || currentTier == 'pro';
}
