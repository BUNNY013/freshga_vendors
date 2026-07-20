import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/vendor_subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  VendorSubscriptionModel? _currentSubscription;
  VendorSubscriptionModel? get currentSubscription => _currentSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  SubscriptionProvider() {
    _fetchSubscription();
  }

  Future<void> _fetchSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = "Not authenticated";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // First get the storeId from the user
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        _error = "User not found";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null || storeId.toString().isEmpty) {
        _error = "No store attached to this user";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch the subscription
      final subDoc = await FirebaseFirestore.instance.collection('store_subscriptions').doc(storeId).get();
      if (subDoc.exists) {
        _currentSubscription = VendorSubscriptionModel.fromJson(subDoc.data()!);
      } else {
        // If they have a store but no subscription doc, default to basic or create a dummy expired one
        _currentSubscription = VendorSubscriptionModel(
          storeId: storeId,
          status: 'expired',
          currentTier: 'basic',
          trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
          cancelAtPeriodEnd: false,
          activeFeatures: [],
        );
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _fetchSubscription();
  }
}
