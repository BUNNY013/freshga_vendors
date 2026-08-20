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
        // Store exists but no subscription doc yet. Create their initial free trial!
        int trialDays = 90; // Fallback default
        try {
          final settingsDoc = await FirebaseFirestore.instance.collection('global_settings').doc('settings').get();
          if (settingsDoc.exists) {
            trialDays = settingsDoc.data()?['default_trial_days'] ?? 90;
          }
        } catch (_) {}

        final newSubscription = VendorSubscriptionModel(
          storeId: storeId,
          status: 'trialing',
          trialEndsAt: DateTime.now().add(Duration(days: trialDays)),
          currentPeriodEnd: null,
        );

        // Save it permanently so the trial date never changes
        await FirebaseFirestore.instance.collection('store_subscriptions').doc(storeId).set(newSubscription.toJson());
        
        _currentSubscription = newSubscription;
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
