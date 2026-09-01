import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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

  bool _isLocationFetched = false;
  bool get isLocationFetched => _isLocationFetched;

  // Step 1: Basic Details
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController alternatePhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // Step 2: Legal & Tax Compliance
  String taxRegistrationType = 'GSTIN'; // GSTIN, EnrolmentNumber, NeedsHelp
  final TextEditingController taxNumberController = TextEditingController();
  File? taxImage;
  String? existingTaxUrl;

  String fssaiStatus = 'Have'; // Have, NeedsHelp
  final TextEditingController fssaiNumberController = TextEditingController();
  File? fssaiImage;
  String? existingFssaiUrl;

  final TextEditingController panNumberController = TextEditingController();
  File? panImage;
  String? existingPanUrl;

  // Address (Moved to Step 1 in UI)
  final TextEditingController businessAddressController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  
  double? latitude;
  double? longitude;


  // Step 5: Bank Details
  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController confirmAccountNumberController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController upiController = TextEditingController();
  String accountType = 'Savings'; // Savings, Current
  File? bankImage;
  String? existingBankUrl;

  OnboardingProvider() {
    _loadDraft();
    _initPhone();
    
    // Listen to pincode changes directly
    pincodeController.addListener(_onPincodeChanged);
    
    // Listen to IFSC changes directly
    ifscController.addListener(_onIfscChanged);
  }

  void _onIfscChanged() {
    final text = ifscController.text.trim();
    if (text.length == 11 && !_isLoading) {
      if (_lastFetchedIfsc != text) {
        _lastFetchedIfsc = text;
        fetchBankDetailsFromIFSC(text);
      }
    } else if (text.length < 11) {
      _lastFetchedIfsc = '';
      if (bankNameController.text.isNotEmpty && !bankNameController.text.contains('Manual')) {
        bankNameController.text = ''; // Clear it if they start deleting the IFSC
      }
    }
  }

  void _onPincodeChanged() {
    final text = pincodeController.text.trim();
    if (text.length == 6 && !_isLoading) {
      // Check if we already fetched this to avoid infinite loops
      if (_lastFetchedPincode != text) {
        _lastFetchedPincode = text;
        fetchLocationFromPincode(text);
      }
    } else if (text.length != 6) {
      _lastFetchedPincode = '';
      _isLocationFetched = false;
      if (_error != null) {
        _error = null;
      }
      notifyListeners();
    }
  }

  String _lastFetchedPincode = '';
  String _lastFetchedIfsc = '';

  void _initPhone() {
    if (_auth.currentUser?.phoneNumber != null) {
      String phone = _auth.currentUser!.phoneNumber!;
      if (phone.startsWith('+91')) {
        phone = phone.substring(3);
      }
      phoneController.text = phone;
    }
  }

  void setTaxRegistrationType(String type) {
    taxRegistrationType = type;
    _saveDraft();
    notifyListeners();
  }

  void setFssaiStatus(String status) {
    fssaiStatus = status;
    _saveDraft();
    notifyListeners();
  }

  void setAccountType(String type) {
    accountType = type;
    _saveDraft();
    notifyListeners();
  }

  Future<void> pickImage(String type, {ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    
    if (pickedFile != null) {
      if (type == 'fssai') {
        fssaiImage = File(pickedFile.path);
      } else if (type == 'pan') {
        panImage = File(pickedFile.path);
      } else if (type == 'tax') {
        taxImage = File(pickedFile.path);
      } else if (type == 'bank') {
        bankImage = File(pickedFile.path);
      }
      notifyListeners();
    }
  }

  // --- Auto Save Logic ---

  Future<void> fetchLocationFromPincode(String pincode) async {
    if (pincode.length != 6) return;
    
    _isLoading = true;
    _error = null; // Clear previous error
    notifyListeners();
    
    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          villageController.text = postOffice['Name'] ?? '';
          cityController.text = postOffice['Block'] ?? '';
          districtController.text = postOffice['District'] ?? '';
          stateController.text = postOffice['State'] ?? '';
          _isLocationFetched = true;
          _error = null;
          _saveDraft();
        } else {
          _error = 'Invalid Pincode';
          _isLocationFetched = false;
          villageController.text = '';
          cityController.text = '';
          districtController.text = '';
          stateController.text = '';
        }
      }
    } catch (e) {
      debugPrint('Pincode error: $e');
      _error = 'Failed to fetch location';
      _isLocationFetched = false;
      villageController.text = '';
      cityController.text = '';
      districtController.text = '';
      stateController.text = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBankDetailsFromIFSC(String ifsc) async {
    if (ifsc.length != 11) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(Uri.parse('https://ifsc.razorpay.com/$ifsc'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bankNameController.text = '${data['BANK']} (${data['BRANCH']})';
        _saveDraft();
      } else {
        _error = 'Invalid IFSC Code. Please check again.';
        bankNameController.text = '';
      }
    } catch (e) {
      debugPrint('IFSC error: $e');
      // Don't block them entirely if API fails, just let them type it manually
      if (bankNameController.text.isEmpty) {
         _error = 'Could not fetch Bank Name. Please enter manually.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeImage(String type) {
    if (type == 'pan') {
      panImage = null;
      existingPanUrl = null;
    } else if (type == 'tax') {
      taxImage = null;
      existingTaxUrl = null;
    } else if (type == 'fssai') {
      fssaiImage = null;
      existingFssaiUrl = null;
    } else if (type == 'bank') {
      bankImage = null;
      existingBankUrl = null;
    }
    notifyListeners();
  }

  Future<void> saveDraft() async {
    await _saveDraft();
  }

  Future<void> _saveDraft() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final draft = {
      // Omit 'status' so we don't accidentally overwrite 'changes_required' back to 'draft'
      'userId': user.uid,
      'applicationId': 'app_${user.uid}',
      'fullName': fullNameController.text,
      'businessName': businessNameController.text,
      'phone': phoneController.text,
      'alternatePhone': alternatePhoneController.text,
      'email': emailController.text,
      'businessAddress': businessAddressController.text,
      'village': villageController.text,
      'city': cityController.text,
      'district': districtController.text,
      'state': stateController.text,
      'pincode': pincodeController.text,
      'latitude': latitude,
      'longitude': longitude,
      
      'taxRegistrationType': taxRegistrationType,
      'taxNumber': taxNumberController.text,
      'fssaiStatus': fssaiStatus,
      'fssaiNumber': fssaiNumberController.text,
      'panNumber': panNumberController.text,
      'accountName': accountNameController.text,
      'accountNumber': accountNumberController.text,
      'ifsc': ifscController.text,
      'bankName': bankNameController.text,
      'accountType': accountType,
      'upi': upiController.text,
      
      // Preserve existing image URLs in the draft
      'taxImage': existingTaxUrl,
      'fssaiCertificateImage': existingFssaiUrl,
      'panImage': existingPanUrl,
      'bankDetails': {
        'accountHolderName': accountNameController.text,
        'accountType': accountType,
        'accountNumber': accountNumberController.text,
        'ifscCode': ifscController.text,
        'bankName': bankNameController.text,
        'upiId': upiController.text,
        'bankImage': existingBankUrl,
      },
      
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _firestore.collection('supplierApplications').doc('app_${user.uid}').set(draft, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save draft to Firestore: $e');
    }
  }

  Future<void> _loadDraft() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('supplierApplications').doc('app_${user.uid}').get();
      if (doc.exists) {
        final draft = doc.data() as Map<String, dynamic>;
        if (draft['status'] == 'approved' || draft['status'] == 'rejected_permanent') return;
        
        fullNameController.text = draft['fullName'] ?? '';
        businessNameController.text = draft['businessName'] ?? '';
        String savedPhone = draft['phone'] ?? _auth.currentUser?.phoneNumber ?? '';
        if (savedPhone.startsWith('+91')) savedPhone = savedPhone.substring(3);
        phoneController.text = savedPhone;
        
        String altPhone = draft['alternatePhone'] ?? '';
        if (altPhone.startsWith('+91')) altPhone = altPhone.substring(3);
        alternatePhoneController.text = altPhone;
        
        emailController.text = draft['email'] ?? '';
        
        businessAddressController.text = draft['businessAddress'] ?? draft['pickupAddress'] ?? '';
        villageController.text = draft['village'] ?? '';
        cityController.text = draft['city'] ?? '';
        districtController.text = draft['district'] ?? '';
        stateController.text = draft['state'] ?? '';
        pincodeController.text = draft['pincode'] ?? '';
        
        if (pincodeController.text.length == 6 && stateController.text.isNotEmpty) {
          _isLocationFetched = true;
        }

        if (draft['latitude'] != null) latitude = (draft['latitude'] as num).toDouble();
        if (draft['longitude'] != null) longitude = (draft['longitude'] as num).toDouble();
        
        taxRegistrationType = draft['taxRegistrationType'] ?? 'GSTIN';
        taxNumberController.text = draft['taxNumber'] ?? '';
        
        fssaiStatus = draft['fssaiStatus'] ?? 'Have';
        fssaiNumberController.text = draft['fssaiNumber'] ?? '';
        panNumberController.text = draft['panNumber'] ?? '';
        
        accountNameController.text = draft['accountName'] ?? draft['bankDetails']?['accountHolderName'] ?? '';
        accountNumberController.text = draft['accountNumber'] ?? draft['bankDetails']?['accountNumber'] ?? '';
        confirmAccountNumberController.text = draft['accountNumber'] ?? draft['bankDetails']?['accountNumber'] ?? '';
        ifscController.text = draft['ifsc'] ?? draft['bankDetails']?['ifscCode'] ?? '';
        bankNameController.text = draft['bankName'] ?? draft['bankDetails']?['bankName'] ?? '';
        accountType = draft['accountType'] ?? draft['bankDetails']?['accountType'] ?? 'Savings';
        upiController.text = draft['upi'] ?? draft['bankDetails']?['upiId'] ?? '';
        
        existingTaxUrl = draft['taxImage'];
        existingFssaiUrl = draft['fssaiCertificateImage'];
        existingPanUrl = draft['panImage'];
        existingBankUrl = draft['bankDetails']?['bankImage'];
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading draft from Firestore: $e');
    }
  }

  void hydrateFromFirestore(Map<String, dynamic> data) {
    fullNameController.text = data['fullName'] ?? '';
    businessNameController.text = data['businessName'] ?? '';
    String savedPhone = data['phone'] ?? _auth.currentUser?.phoneNumber ?? '';
    if (savedPhone.startsWith('+91')) savedPhone = savedPhone.substring(3);
    phoneController.text = savedPhone;
    
    String altPhone = data['alternatePhone'] ?? '';
    if (altPhone.startsWith('+91')) altPhone = altPhone.substring(3);
    alternatePhoneController.text = altPhone;
    
    emailController.text = data['email'] ?? '';
    
    businessAddressController.text = data['businessAddress'] ?? data['pickupAddress'] ?? '';
    villageController.text = data['village'] ?? '';
    cityController.text = data['city'] ?? '';
    districtController.text = data['district'] ?? '';
    stateController.text = data['state'] ?? '';
    pincodeController.text = data['pincode'] ?? '';
    
    taxRegistrationType = data['taxRegistrationType'] ?? 'GSTIN';
    taxNumberController.text = data['taxNumber'] ?? '';
    existingTaxUrl = data['taxImage'];
    
    fssaiStatus = data['fssaiStatus'] ?? 'Have';
    fssaiNumberController.text = data['fssaiNumber'] ?? '';
    existingFssaiUrl = data['fssaiCertificateImage'];
    
    panNumberController.text = data['panNumber'] ?? '';
    existingPanUrl = data['panImage'];
    
    final bank = data['bankDetails'] as Map<String, dynamic>? ?? {};
    accountNameController.text = bank['accountHolderName'] ?? '';
    accountNumberController.text = bank['accountNumber'] ?? '';
    confirmAccountNumberController.text = bank['accountNumber'] ?? '';
    ifscController.text = bank['ifscCode'] ?? '';
    bankNameController.text = bank['bankName'] ?? '';
    upiController.text = bank['upiId'] ?? '';
    existingBankUrl = bank['bankImage'];
    
    notifyListeners();
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
      String taxUrl = existingTaxUrl ?? '';
      String fssaiUrl = existingFssaiUrl ?? '';
      String panUrl = existingPanUrl ?? '';
      String bankUrl = existingBankUrl ?? '';

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      if (taxImage != null) {
        if (!taxImage!.existsSync()) throw Exception('Tax document photo was lost from device memory. Please re-select it in Step 2.');
        final taxRef = _storage.ref().child('vendor_documents/$userId/tax.jpg');
        await taxRef.putFile(taxImage!, metadata);
        taxUrl = await taxRef.getDownloadURL();
      }

      if (fssaiImage != null) {
        if (!fssaiImage!.existsSync()) throw Exception('FSSAI certificate photo was lost from device memory. Please re-select it in Step 2.');
        final fssaiRef = _storage.ref().child('vendor_documents/$userId/fssai.jpg');
        await fssaiRef.putFile(fssaiImage!, metadata);
        fssaiUrl = await fssaiRef.getDownloadURL();
      }

      if (panImage != null) {
        if (!panImage!.existsSync()) throw Exception('PAN card photo was lost from device memory. Please re-select it in Step 2.');
        final panRef = _storage.ref().child('vendor_documents/$userId/pan.jpg');
        await panRef.putFile(panImage!, metadata);
        panUrl = await panRef.getDownloadURL();
      }

      if (bankImage != null) {
        if (!bankImage!.existsSync()) throw Exception('Bank passbook/cheque photo was lost from device memory. Please re-select it.');
        final bankRef = _storage.ref().child('vendor_documents/$userId/bank.jpg');
        await bankRef.putFile(bankImage!, metadata);
        bankUrl = await bankRef.getDownloadURL();
      }

      // 2. Create Application Model
      final application = SupplierApplicationModel(
        applicationId: applicationId,
        userId: userId,
        fullName: fullNameController.text.trim(),
        businessName: businessNameController.text.trim(),
        phone: '+91${phoneController.text.trim()}',
        alternatePhone: alternatePhoneController.text.trim().isNotEmpty ? '+91${alternatePhoneController.text.trim()}' : '',
        email: emailController.text.trim(),
        
        taxRegistrationType: taxRegistrationType,
        taxNumber: taxNumberController.text.trim(),
        taxImage: taxUrl,
        
        fssaiStatus: fssaiStatus,
        fssaiNumber: fssaiNumberController.text.trim(),
        fssaiCertificateImage: fssaiUrl,
        
        panNumber: panNumberController.text.trim(),
        panImage: panUrl,
        
        businessAddress: businessAddressController.text.trim(),
        village: villageController.text.trim(),
        city: cityController.text.trim(),
        district: districtController.text.trim(),
        state: stateController.text.trim(),
        pincode: pincodeController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        bankDetails: {
          'accountHolderName': accountNameController.text.trim(),
          'accountType': accountType,
          'accountNumber': accountNumberController.text.trim(),
          'ifscCode': ifscController.text.trim(),
          'bankName': bankNameController.text.trim(),
          'upiId': upiController.text.trim(),
          'bankImage': bankUrl,
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
    alternatePhoneController.dispose();
    emailController.dispose();
    businessAddressController.dispose();
    villageController.dispose();
    cityController.dispose();
    districtController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    taxNumberController.dispose();
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
