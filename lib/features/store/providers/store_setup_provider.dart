import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/store_model.dart';

class StoreSetupProvider extends ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  String _city = '';
  String get city => _city;

  String _state = '';
  String get state => _state;

  StoreSetupProvider() {
    _fetchVendorLocation();
  }

  Future<void> _fetchVendorLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint("Fetching location for user: ${user.uid}");
        final querySnapshot = await FirebaseFirestore.instance
            .collection('supplier_applications')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          _city = data['city'] ?? '';
          _state = data['state'] ?? '';
          debugPrint("Found location: $_city, $_state");
          notifyListeners();
        } else {
          debugPrint("No supplier application found for user.");
        }
      } else {
        debugPrint("No current user found.");
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  String? _handleError;
  String? get handleError => _handleError;

  File? _logoFile;
  File? get logoFile => _logoFile;

  File? _bannerFile;
  File? get bannerFile => _bannerFile;

  String _storeName = '';
  String get storeName => _storeName;

  String _storeHandle = '';
  String get storeHandle => _storeHandle;
  
  final TextEditingController handleController = TextEditingController();

  bool _isCheckingHandle = false;
  bool get isCheckingHandle => _isCheckingHandle;

  bool? _isHandleAvailable;
  bool? get isHandleAvailable => _isHandleAvailable;

  Timer? _debounce;

  String _brandStory = '';
  String get brandStory => _brandStory;

  String _instagramLink = '';
  String get instagramLink => _instagramLink;

  String _youtubeLink = '';
  String get youtubeLink => _youtubeLink;

  String _facebookLink = '';
  String get facebookLink => _facebookLink;

  String _whatsappNumber = '';
  String get whatsappNumber => _whatsappNumber;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void nextStep() {
    if (_currentStep == 3) {
      if (_storeName.trim().isEmpty) {
        _errorMessage = "Please enter your Store Name.";
        notifyListeners();
        return;
      }
      if (_storeHandle.isEmpty || _isHandleAvailable != true || _handleError != null) {
        _errorMessage = "Please choose a valid and available Store Handle.";
        notifyListeners();
        return;
      }
      if (_brandStory.trim().isEmpty) {
        _errorMessage = "Please write a short Brand Story.";
        notifyListeners();
        return;
      }
    }
    
    _errorMessage = null;
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

  void setStoreName(String val) {
    _storeName = val;
    notifyListeners();
  }

  void setStoreHandle(String val) {
    final formatted = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_\.]'), '');
    
    if (formatted != val) {
       handleController.text = formatted;
       handleController.selection = TextSelection.fromPosition(TextPosition(offset: formatted.length));
    }
    
    _storeHandle = formatted;
    _isHandleAvailable = null;
    _handleError = null;
    
    if (formatted.isNotEmpty) {
      // Synchronous Instagram-style validation
      if (formatted.length < 3) {
        _handleError = "Handle must be at least 3 characters long.";
      } else if (RegExp(r'^[0-9]').hasMatch(formatted)) {
        _handleError = "Handle cannot start with a number.";
      } else if (formatted.startsWith('.') || formatted.startsWith('_')) {
        _handleError = "Handle cannot start with a period or underscore.";
      } else if (formatted.endsWith('.')) {
        _handleError = "Handle cannot end with a period.";
      } else if (formatted.contains('..')) {
        _handleError = "Handle cannot contain consecutive periods.";
      }

      if (_handleError != null) {
        _isHandleAvailable = false;
        _isCheckingHandle = false;
        notifyListeners();
        return;
      }

      _isCheckingHandle = true;
      notifyListeners();
      
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _checkHandleAvailability(formatted);
      });
    } else {
      _isCheckingHandle = false;
      notifyListeners();
    }
  }

  Future<void> _checkHandleAvailability(String handle) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('storeSlug', isEqualTo: handle)
          .limit(1)
          .get();
          
      _isHandleAvailable = snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint("Error checking handle: $e");
      _isHandleAvailable = false;
    } finally {
      _isCheckingHandle = false;
      notifyListeners();
    }
  }

  void setBrandStory(String val) {
    _brandStory = val;
    notifyListeners();
  }

  void setInstagramLink(String val) {
    _instagramLink = val;
    notifyListeners();
  }

  void setYoutubeLink(String val) {
    _youtubeLink = val;
    notifyListeners();
  }

  void setFacebookLink(String val) {
    _facebookLink = val;
    notifyListeners();
  }

  void setWhatsappNumber(String val) {
    _whatsappNumber = val;
    notifyListeners();
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Logo',
            toolbarColor: const Color(0xFFE94560), // AppColors.primary
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Logo',
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile != null) {
        _logoFile = File(croppedFile.path);
        notifyListeners();
      }
    }
  }

  Future<void> pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Banner',
            toolbarColor: const Color(0xFFE94560), // AppColors.primary
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Banner',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        _bannerFile = File(croppedFile.path);
        notifyListeners();
      }
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
        storeSlug: _storeHandle, // We now use their chosen unique handle
        description: _brandStory,
        logo: logoUrl,
        banner: bannerUrl,
        city: _city,
        state: _state,
        instagramLink: _instagramLink,
        youtubeLink: _youtubeLink,
        facebookLink: _facebookLink,
        whatsappNumber: _whatsappNumber,
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
        shippingConfig: {},
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
