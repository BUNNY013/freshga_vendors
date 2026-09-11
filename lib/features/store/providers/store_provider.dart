import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/store_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/delivery_area_model.dart';

class StoreProvider extends ChangeNotifier {
  StoreModel? _store;
  StoreModel? get store => _store;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<DocumentSnapshot>? _storeSubscription;

  StoreProvider() {
    _init();
  }

  Future<void> _init() async {
    await fetchStore();
  }

  Future<void> fetchStore() async {
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

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        _error = "User not found";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null || storeId.toString().isEmpty) {
        _error = "No store attached";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cancel any existing subscription
      _storeSubscription?.cancel();

      // Listen in real-time
      _storeSubscription = FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .snapshots()
          .listen(
        (storeDoc) {
          if (storeDoc.exists) {
            _store = StoreModel.fromJson(storeDoc.data()!);
            _error = null;
          } else {
            _error = "Store document not found";
            _store = null;
          }
          if (_isLoading) {
            _isLoading = false;
          }
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _storeSubscription?.cancel();
    super.dispose();
  }

  // --- Optimistic Updates for Shipping Settings ---

  Future<void> updateShippingMode(String mode) async {
    if (_store == null) return;

    final previousStore = _store;

    // Optimistic UI update
    final updatedConfig = Map<String, dynamic>.from(_store!.shippingConfig);
    updatedConfig['shippingMode'] = mode;

    _store = _store!.copyWith(shippingConfig: updatedConfig);
    notifyListeners();

    // Background Firebase update
    try {
      await FirebaseFirestore.instance.collection('stores').doc(_store!.storeId).update({
        'shippingConfig.shippingMode': mode,
      });
    } catch (e) {
      debugPrint("Failed to update shipping mode: $e");
      // Roll back the optimistic update so the UI matches what's actually persisted
      _store = previousStore;
      _error = "Failed to update shipping mode. Please try again.";
      notifyListeners();
    }
  }

  Future<void> updateDeliveryArea(int index, DeliveryAreaModel updatedArea) async {
    if (_store == null) return;

    final previousStore = _store;

    // Optimistic UI update
    final newAreas = List<DeliveryAreaModel>.from(_store!.deliveryAreas);
    newAreas[index] = updatedArea;
    _store = _store!.copyWith(deliveryAreas: newAreas);
    notifyListeners();

    // Background Firebase update
    try {
      await FirebaseFirestore.instance.collection('stores').doc(_store!.storeId).update({
        'deliveryAreas': newAreas.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      debugPrint("Failed to update delivery area: $e");
      _store = previousStore;
      _error = "Failed to update delivery area. Please try again.";
      notifyListeners();
    }
  }

  Future<void> addDeliveryArea(DeliveryAreaModel newArea) async {
    if (_store == null) return;

    final previousStore = _store;

    // Optimistic UI update
    final newAreas = List<DeliveryAreaModel>.from(_store!.deliveryAreas);
    newAreas.add(newArea);
    _store = _store!.copyWith(deliveryAreas: newAreas);
    notifyListeners();

    // Background Firebase update
    try {
      await FirebaseFirestore.instance.collection('stores').doc(_store!.storeId).update({
        'deliveryAreas': newAreas.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      debugPrint("Failed to add delivery area: $e");
      _store = previousStore;
      _error = "Failed to add delivery area. Please try again.";
      notifyListeners();
    }
  }

  Future<void> updateSocialLinks({
    required String instagram,
    required String facebook,
    required String youtube,
    required String whatsapp,
  }) async {
    if (_store == null) return;

    final previousStore = _store;

    _store = _store!.copyWith(
      instagramLink: instagram,
      facebookLink: facebook,
      youtubeLink: youtube,
      whatsappNumber: whatsapp,
    );
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('stores').doc(_store!.storeId).update({
        'instagramLink': instagram,
        'facebookLink': facebook,
        'youtubeLink': youtube,
        'whatsappNumber': whatsapp,
      });
    } catch (e) {
      debugPrint("Failed to update social links: $e");
      _store = previousStore;
      _error = "Failed to update social links.";
      notifyListeners();
    }
  }
}
