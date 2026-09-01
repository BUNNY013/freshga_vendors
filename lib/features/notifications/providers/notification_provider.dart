import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  StreamSubscription? _notificationSubscription;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _init();
  }

  void _init() {
    // Listen to Auth State to initialize notifications for the correct user
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          final storeId = userDoc.data()?['storeId'] as String?;
          if (storeId != null && storeId.isNotEmpty) {
            _subscribeToNotifications(storeId);
          }
        } catch (e) {
          debugPrint('Error fetching storeId for notifications: $e');
        }
      } else {
        _cancelSubscription();
        _notifications = [];
        notifyListeners();
      }
    });
  }

  void _subscribeToNotifications(String vendorId) {
    _cancelSubscription();
    _isLoading = true;
    notifyListeners();

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs.map((doc) => NotificationModel.fromJson(doc.data(), doc.id)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      
      try {
        await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
      } catch (e) {
        // Revert on error
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        notifyListeners();
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Optimistic update
    final unreadList = _notifications.where((n) => !n.isRead).toList();
    if (unreadList.isEmpty) return;
    
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    
    try {
      final batch = _firestore.batch();
      for (var n in unreadList) {
        batch.update(_firestore.collection('notifications').doc(n.id), {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      // On failure, re-subscribe to get the real state back
      _subscribeToNotifications(user.uid);
    }
  }

  // --- Helper method to simulate a notification from the frontend for testing ---
  Future<void> simulateNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final newNotif = NotificationModel(
      id: '',
      vendorId: user.uid,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('notifications').add(newNotif.toJson());
  }

  void _cancelSubscription() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
}
