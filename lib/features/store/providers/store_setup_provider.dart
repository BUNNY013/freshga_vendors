import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/store_model.dart';

class StoreSetupProvider extends ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  File? _logoFile;
  File? get logoFile => _logoFile;

  File? _bannerFile;
  File? get bannerFile => _bannerFile;

  String _storeName = '';
  String get storeName => _storeName;

  String _brandStory = '';
  String get brandStory => _brandStory;

  String _instagramLink = '';
  String get instagramLink => _instagramLink;

  String _dispatchTime = '24 hours';
  String get dispatchTime => _dispatchTime;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void nextStep() {
    if (_currentStep < 6) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setStoreName(String val) {
    _storeName = val;
    notifyListeners();
  }

  void setBrandStory(String val) {
    _brandStory = val;
    notifyListeners();
  }

  void setInstagramLink(String val) {
    _instagramLink = val;
    notifyListeners();
  }

  void setDispatchTime(String val) {
    _dispatchTime = val;
    notifyListeners();
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _logoFile = File(picked.path);
      notifyListeners();
    }
  }

  Future<void> pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _bannerFile = File(picked.path);
      notifyListeners();
    }
  }

  Future<bool> publishStore() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      String logoUrl = '';
      String bannerUrl = '';

      final storeId = FirebaseFirestore.instance.collection('stores').doc().id;

      if (_logoFile != null) {
        final ref = FirebaseStorage.instance.ref().child('store_assets/logos/$storeId.jpg');
        await ref.putFile(_logoFile!);
        logoUrl = await ref.getDownloadURL();
      }

      if (_bannerFile != null) {
        final ref = FirebaseStorage.instance.ref().child('store_assets/banners/$storeId.jpg');
        await ref.putFile(_bannerFile!);
        bannerUrl = await ref.getDownloadURL();
      }

      final store = StoreModel(
        storeId: storeId,
        ownerId: user.uid,
        storeName: _storeName,
        storeSlug: _storeName.toLowerCase().replaceAll(' ', '-'),
        description: _brandStory,
        logo: logoUrl,
        banner: bannerUrl,
        instagramLink: _instagramLink,
        youtubeLink: '',
        facebookLink: '',
        categories: [],
        followers: 0,
        likesCount: 0,
        productsCount: 0,
        rating: 0,
        totalReviews: 0,
        totalOrders: 0,
        verified: true,
        isFeatured: false,
        isActive: true,
        dispatchTime: _dispatchTime,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await FirebaseFirestore.instance.collection('stores').doc(storeId).set(store.toJson());
      
      // Update user doc with storeId
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'storeId': storeId,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
