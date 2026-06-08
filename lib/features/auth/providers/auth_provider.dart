import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/supplier_application_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  SupplierApplicationModel? _applicationModel;
  SupplierApplicationModel? get applicationModel => _applicationModel;

  String? _verificationId;
  String? get verificationId => _verificationId;

  int? _resendToken;
  int? get resendToken => _resendToken;

  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _setUnauthenticated();
      } else {
        await _fetchUserData(user.uid, user.phoneNumber ?? '');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setUnauthenticated() {
    _state = AuthState.unauthenticated;
    _userModel = null;
    _applicationModel = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid, String phone) async {
    _state = AuthState.loading;
    notifyListeners();
    
    try {
      _userModel = await _authService.getUserData(uid);
      if (_userModel == null) {
        // Create new user document
        final newUser = UserModel(
          userId: uid,
          role: 'supplier',
          phone: phone,
          isVerified: false,
          isBlocked: false,
          storeId: '',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _authService.createUserDoc(newUser);
        _userModel = newUser;
      }
      
      // Fetch application status
      _applicationModel = await _authService.getSupplierApplication(uid);
      
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> verifyPhone(String phone, {VoidCallback? codeSentCallback}) async {
    _setLoading(true);
    try {
      await _authService.verifyPhone(
        phoneNumber: phone,
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          _resendToken = resendToken;
          _setLoading(false);
          if (codeSentCallback != null) codeSentCallback();
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          _errorMessage = _getFriendlyErrorMessage(e);
          notifyListeners();
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _authService.signInWithCredential(credential);
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> resendOTP(String phone) async {
    _setLoading(true);
    try {
      await _authService.verifyPhone(
        phoneNumber: phone,
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          _resendToken = resendToken;
          _setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          _errorMessage = _getFriendlyErrorMessage(e);
          notifyListeners();
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _authService.signInWithCredential(credential);
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _errorMessage = 'Session expired. Please request a new code.';
      notifyListeners();
      return false;
    }
    
    _setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _authService.signInWithCredential(credential);
      // Wait a bit to allow the authState listener to trigger and fetch data
      // which will change state to authenticated
      return true; 
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Invalid OTP or expired. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshApplicationStatus() async {
    if (_userModel == null) return;
    _applicationModel = await _authService.getSupplierApplication(_userModel!.userId);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
  
  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number you entered is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'quota-exceeded':
        return 'Service quota exceeded. Please contact support.';
      case 'session-expired':
        return 'Your session has expired. Please try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
