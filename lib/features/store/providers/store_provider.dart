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

      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
      if (storeDoc.exists) {
        _store = StoreModel.fromJson(storeDoc.data()!);
      } else {
        _error = "Store document not found";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
