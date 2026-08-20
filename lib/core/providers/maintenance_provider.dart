import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceProvider extends ChangeNotifier {
  bool _isMaintenanceMode = false;
  String _message = 'FreshGa HomeMades is currently undergoing scheduled maintenance to serve you better. We\'ll be back soon!';
  String _endTime = '';

  bool get isMaintenanceMode => _isMaintenanceMode;
  String get message => _message;
  String get endTime => _endTime;

  StreamSubscription<DocumentSnapshot>? _subscription;

  MaintenanceProvider() {
    _initListener();
  }

  void _initListener() {
    _subscription = FirebaseFirestore.instance
        .collection('global_settings')
        .doc('settings')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final active = data['vendor_maintenance_mode'] ?? false;
        
        if (_isMaintenanceMode != active) {
          _isMaintenanceMode = active;
          _message = data['maintenance_message'] ?? _message;
          _endTime = data['maintenance_end_time'] ?? '';
          notifyListeners();
        } else if (_isMaintenanceMode) {
          // Update message/time if they change while maintenance is active
          bool updated = false;
          final newMessage = data['maintenance_message'] ?? 'FreshGa HomeMades is currently undergoing scheduled maintenance to serve you better. We\'ll be back soon!';
          final newTime = data['maintenance_end_time'] ?? '';
          
          if (_message != newMessage) {
            _message = newMessage;
            updated = true;
          }
          if (_endTime != newTime) {
            _endTime = newTime;
            updated = true;
          }
          if (updated) {
            notifyListeners();
          }
        }
      }
    }, onError: (e) {
      // Ignore errors if logged out
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
