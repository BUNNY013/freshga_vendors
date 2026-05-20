import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/supplier_application_model.dart';
import 'package:image_picker/image_picker.dart';

class OnboardingProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _prefsKey = 'onboarding_draft';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Step 1: Basic Details
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  // Step 2: Business Info
  final TextEditingController businessDescController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  List<String> selectedFoodCategories = [];
  String? selectedDispatchTime;

  // Step 3: Address Details
  final TextEditingController businessAddressController = TextEditingController();
  final TextEditingController pickupAddressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  // Step 4: Legal Documents
  final TextEditingController fssaiNumberController = TextEditingController();
  final TextEditingController panNumberController = TextEditingController();
  File? fssaiImage;
  File? panImage;

  // Step 5: Bank Details
  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController confirmAccountNumberController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController upiController = TextEditingController();

  OnboardingProvider() {
    _loadDraft();
    _initPhone();
  }

  void _initPhone() {
    if (_auth.currentUser?.phoneNumber != null) {
      phoneController.text = _auth.currentUser!.phoneNumber!;
    }
  }

  void toggleCategory(String category) {
    if (selectedFoodCategories.contains(category)) {
      selectedFoodCategories.remove(category);
    } else {
      selectedFoodCategories.add(category);
    }
    _saveDraft();
    notifyListeners();
  }

  void setDispatchTime(String time) {
    selectedDispatchTime = time;
    _saveDraft();
    notifyListeners();
  }

  Future<void> pickImage(bool isFssai) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      if (isFssai) {
        fssaiImage = File(pickedFile.path);
      } else {
        panImage = File(pickedFile.path);
      }
      notifyListeners();
    }
  }

  // --- Auto Save Logic ---

  Future<void> saveDraft() async {
    await _saveDraft();
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    
    final draft = {
      'fullName': fullNameController.text,
      'businessName': businessNameController.text,
      'phone': phoneController.text,
      'email': emailController.text,
      'instagramLink': instagramController.text,
      'businessDescription': businessDescController.text,
      'experience': experienceController.text,
      'selectedFoodCategories': selectedFoodCategories,
      'selectedDispatchTime': selectedDispatchTime,
      'businessAddress': businessAddressController.text,
      'pickupAddress': pickupAddressController.text,
      'city': cityController.text,
      'state': stateController.text,
      'pincode': pincodeController.text,
      'fssaiNumber': fssaiNumberController.text,
      'panNumber': panNumberController.text,
      'accountName': accountNameController.text,
      'accountNumber': accountNumberController.text,
      'ifsc': ifscController.text,
      'bankName': bankNameController.text,
      'upi': upiController.text,
    };

    await prefs.setString(_prefsKey, json.encode(draft));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftString = prefs.getString(_prefsKey);
    
    if (draftString != null) {
      try {
        final draft = json.decode(draftString) as Map<String, dynamic>;
        
        fullNameController.text = draft['fullName'] ?? '';
        businessNameController.text = draft['businessName'] ?? '';
        phoneController.text = draft['phone'] ?? _auth.currentUser?.phoneNumber ?? '';
        emailController.text = draft['email'] ?? '';
        instagramController.text = draft['instagramLink'] ?? '';
        
        businessDescController.text = draft['businessDescription'] ?? '';
        experienceController.text = draft['experience'] ?? '';
        
        if (draft['selectedFoodCategories'] != null) {
          selectedFoodCategories = List<String>.from(draft['selectedFoodCategories']);
        }
        selectedDispatchTime = draft['selectedDispatchTime'];
        
        businessAddressController.text = draft['businessAddress'] ?? '';
        pickupAddressController.text = draft['pickupAddress'] ?? '';
        cityController.text = draft['city'] ?? '';
        stateController.text = draft['state'] ?? '';
        pincodeController.text = draft['pincode'] ?? '';
        
        fssaiNumberController.text = draft['fssaiNumber'] ?? '';
        panNumberController.text = draft['panNumber'] ?? '';
        
        accountNameController.text = draft['accountName'] ?? '';
        accountNumberController.text = draft['accountNumber'] ?? '';
        confirmAccountNumberController.text = draft['accountNumber'] ?? '';
        ifscController.text = draft['ifsc'] ?? '';
        bankNameController.text = draft['bankName'] ?? '';
        upiController.text = draft['upi'] ?? '';
        
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading draft: $e');
      }
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // --- Submission Logic ---

  Future<bool> submitApplication() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final applicationId = 'app_$userId';

      // 1. Upload Images
      String fssaiUrl = '';
      String panUrl = '';

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      if (fssaiImage != null) {
        final fssaiRef = _storage.ref().child('vendor_documents/$userId/fssai.jpg');
        await fssaiRef.putFile(fssaiImage!, metadata);
        fssaiUrl = await fssaiRef.getDownloadURL();
      }

      if (panImage != null) {
        final panRef = _storage.ref().child('vendor_documents/$userId/pan.jpg');
        await panRef.putFile(panImage!, metadata);
        panUrl = await panRef.getDownloadURL();
      }

      // 2. Create Application Model
      final application = SupplierApplicationModel(
        applicationId: applicationId,
        userId: userId,
        fullName: fullNameController.text.trim(),
        businessName: businessNameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        instagramLink: instagramController.text.trim(),
        businessDescription: businessDescController.text.trim(),
        foodCategories: selectedFoodCategories,
        dispatchTime: selectedDispatchTime ?? '',
        experience: experienceController.text.trim(),
        businessAddress: businessAddressController.text.trim(),
        pickupAddress: pickupAddressController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        pincode: pincodeController.text.trim(),
        fssaiNumber: fssaiNumberController.text.trim(),
        fssaiCertificateImage: fssaiUrl,
        panNumber: panNumberController.text.trim(),
        panImage: panUrl,
        bankDetails: {
          'accountHolderName': accountNameController.text.trim(),
          'accountNumber': accountNumberController.text.trim(),
          'ifscCode': ifscController.text.trim(),
          'bankName': bankNameController.text.trim(),
          'upiId': upiController.text.trim(),
        },
        status: 'pending',
        adminRemarks: '',
        submittedAt: DateTime.now().toIso8601String(),
        verifiedAt: '',
      );

      // 3. Save to Firestore
      await _firestore
          .collection('supplierApplications')
          .doc(applicationId)
          .set(application.toJson());

      // 4. Clear Draft
      await clearDraft();

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    businessNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    instagramController.dispose();
    businessDescController.dispose();
    experienceController.dispose();
    businessAddressController.dispose();
    pickupAddressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    fssaiNumberController.dispose();
    panNumberController.dispose();
    accountNameController.dispose();
    accountNumberController.dispose();
    confirmAccountNumberController.dispose();
    ifscController.dispose();
    bankNameController.dispose();
    upiController.dispose();
    super.dispose();
  }
}
