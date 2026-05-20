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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  SupplierApplicationModel? _applicationModel;
  SupplierApplicationModel? get applicationModel => _applicationModel;

  String? _verificationId;
  String? get verificationId => _verificationId;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _setUnauthenticated();
      } else {
        await _fetchUserData(user.uid, user.phoneNumber ?? '');
      }
    });
  }

  void _setLoading() {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _state = AuthState.unauthenticated;
    _userModel = null;
    _applicationModel = null;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid, String phone) async {
    _setLoading();
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
    notifyListeners();
  }

  Future<void> verifyPhone(String phone, {VoidCallback? codeSentCallback}) async {
    _setLoading();
    try {
      await _authService.verifyPhone(
        phoneNumber: phone,
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          _state = AuthState.unauthenticated; // Reset loading
          notifyListeners();
          if (codeSentCallback != null) codeSentCallback();
        },
        verificationFailed: (FirebaseAuthException e) {
          _state = AuthState.error;
          _errorMessage = e.message;
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
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) return;
    _setLoading();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _authService.signInWithCredential(credential);
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Invalid OTP or expired. Please try again.';
      notifyListeners();
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
}
