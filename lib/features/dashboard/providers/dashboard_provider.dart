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

  int get lowStockCount => _lowStockCount;
  int get outOfStockCount => _outOfStockCount;
  int get pendingOrdersCount => _pendingOrdersCount;

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
            bool hasLowVariant = false;
            bool allOut = true;
            bool hasVariants = product.variants.isNotEmpty;

            if (hasVariants) {
              for (var variant in product.variants) {
                if (variant.manageStock) {
                  if (variant.stock > 0) {
                    allOut = false;
                    if (variant.stock <= 5) {
                      hasLowVariant = true;
                    }
                  }
                } else {
                  allOut = false; // If stock is not managed, it's technically infinite
                }
              }

              if (allOut) {
                out++;
              } else if (hasLowVariant) {
                low++;
              }
            }
          }
        } catch (e) {
          print("Error parsing product in dashboard metric: $e");
        }
      }

      _lowStockCount = low;
      _outOfStockCount = out;
      notifyListeners();
    });

    _ordersSubscription = _firestore
        .collection('orders')
        .where('storeId', isEqualTo: _storeId)
        .where('orderStatus', whereIn: ['New', 'Accepted', 'Packed'])
        .snapshots()
        .listen((snapshot) {
      _pendingOrdersCount = snapshot.docs.length;
      notifyListeners();
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
