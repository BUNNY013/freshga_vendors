import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/store_model.dart';
import '../../data/repositories/store_repository.dart';

class StoreSetupProvider extends ChangeNotifier {
  final StoreRepository _repository = StoreRepository();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Form Fields
  File? _logoFile;
  File? get logoFile => _logoFile;

  File? _bannerFile;
  File? get bannerFile => _bannerFile;

  String _storeName = '';
  String _brandStory = '';
  String _instagramLink = '';
  String _dispatchTime = '24 hours';
  
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

  void nextStep() {
    if (_currentStep < 5) {
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

  Future<void> pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _logoFile = File(image.path);
      notifyListeners();
    }
  }

  Future<void> pickBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _bannerFile = File(image.path);
      notifyListeners();
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _errorMessage = 'Failed to upload image: $e';
      return null;
    }
  }

  Future<bool> publishStore() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String logoUrl = '';
      if (_logoFile != null) {
        final url = await _uploadImage(_logoFile!, 'stores/${user.uid}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (url != null) logoUrl = url;
      }

      String bannerUrl = '';
      if (_bannerFile != null) {
        final url = await _uploadImage(_bannerFile!, 'stores/${user.uid}/banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (url != null) bannerUrl = url;
      }

      final storeId = user.uid; // One store per vendor assumption
      
      // Basic slug generation
      final storeSlug = _storeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

      final store = StoreModel(
        storeId: storeId,
        ownerId: user.uid,
        storeName: _storeName,
        storeSlug: storeSlug,
        description: _brandStory,
        logo: logoUrl,
        banner: bannerUrl,
        instagramLink: _instagramLink,
        categories: [], // To be added later
        dispatchTime: _dispatchTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createStore(store);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
