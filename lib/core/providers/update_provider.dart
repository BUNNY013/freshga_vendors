import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateProvider extends ChangeNotifier {
  bool _isForceUpdate = false;
  bool _isSoftUpdate = false;
  bool _hasDismissedSoftUpdate = false;
  String _updateFeatures = '';
  String _storeUrl = '';

  bool get isForceUpdate => _isForceUpdate;
  bool get isSoftUpdate => _isSoftUpdate && !_hasDismissedSoftUpdate;
  String get updateFeatures => _updateFeatures;
  String get storeUrl => _storeUrl;

  void dismissSoftUpdate() {
    _hasDismissedSoftUpdate = true;
    notifyListeners();
  }

  StreamSubscription<DocumentSnapshot>? _subscription;

  UpdateProvider() {
    _initListener();
  }

  Future<void> _initListener() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    _subscription = FirebaseFirestore.instance
        .collection('global_settings')
        .doc('settings')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final minVersion = data['vendor_app_minimum_version'] ?? '1.0.0';
        final latestVersion = data['vendor_app_latest_version'] ?? '1.0.0';
        _updateFeatures = data['update_features'] ?? '';
        
        if (Platform.isIOS) {
          _storeUrl = data['ios_store_url'] ?? '';
        } else {
          _storeUrl = data['android_store_url'] ?? '';
        }

        final isForce = _compareVersions(currentVersion, minVersion) < 0;
        final isSoft = !isForce && _compareVersions(currentVersion, latestVersion) < 0;

        if (_isForceUpdate != isForce || _isSoftUpdate != isSoft) {
          _isForceUpdate = isForce;
          _isSoftUpdate = isSoft;
          notifyListeners();
        }
      }
    });
  }

  // Returns -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      int p1 = i < v1Parts.length ? v1Parts[i] : 0;
      int p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
