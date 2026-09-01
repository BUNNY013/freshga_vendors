import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/product_model.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _lowStockCount = 0;
  int _outOfStockCount = 0;
  int _pendingOrdersCount = 0;
  int _expiringOrdersCount = 0;

  int get lowStockCount => _lowStockCount;
  int get outOfStockCount => _outOfStockCount;
  int get pendingOrdersCount => _pendingOrdersCount;
  int get expiringOrdersCount => _expiringOrdersCount;

  String? _storeId;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _ordersSubscription;

  void subscribeToStore(String storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    _subscribe();
  }

  void _subscribe() {
    _cancelSubscriptions();
    if (_storeId == null || _storeId!.isEmpty) return;

    _productsSubscription = _firestore
        .collection('products')
        .where('storeId', isEqualTo: _storeId)
        .snapshots()
        .listen((snapshot) {
      int low = 0;
      int out = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['productId'] = doc.id;
          final product = ProductModel.fromJson(data);
          
          // Only count active/live products
          if (product.status.contains('Live')) {
            if (product.variants.isNotEmpty) {
              final isOutOfStock = product.variants.any((v) => v.manageStock && v.stock <= 0);
              final isLowStock = product.variants.any((v) => v.manageStock && v.stock > 0 && v.stock <= 5);

              if (isOutOfStock) {
                out++;
              } else if (isLowStock) {
                low++;
              }
            }
          }
        } catch (e) {
          debugPrint("Error parsing product in dashboard metric: $e");
        }
      }

      _lowStockCount = low;
      _outOfStockCount = out;
      notifyListeners();
    }, onError: (error) {
      debugPrint("PRODUCTS STREAM ERROR: $error");
    });

    _ordersSubscription = _firestore
        .collection('orders')
        .where('storeId', isEqualTo: _storeId)
        .where('orderStatus', whereIn: ['New', 'Accepted', 'Packed'])
        .snapshots()
        .listen((snapshot) {
      int expiring = 0;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if ((data['orderStatus'] ?? '').toString().toLowerCase() == 'new') {
          if (data['expiresAt'] != null) {
            final expiresAt = (data['expiresAt'] as Timestamp).toDate();
            final hoursLeft = expiresAt.difference(now).inMinutes / 60.0;
            if (hoursLeft <= 1.0) {
              expiring++;
            }
          }
        }
      }
      _pendingOrdersCount = snapshot.docs.length;
      _expiringOrdersCount = expiring;
      notifyListeners();
    }, onError: (error) {
      debugPrint("ORDERS STREAM ERROR: $error");
    });
  }

  void _cancelSubscriptions() {
    _productsSubscription?.cancel();
    _ordersSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
