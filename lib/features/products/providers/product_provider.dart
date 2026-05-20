import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/user_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<File> _selectedImages = [];
  List<File> get selectedImages => _selectedImages;

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      _selectedImages.addAll(picked.map((e) => File(e.path)));
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final image = _selectedImages.removeAt(oldIndex);
    _selectedImages.insert(newIndex, image);
    notifyListeners();
  }

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("Not authenticated");

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userModel = UserModel.fromJson(userDoc.data()!);
      if (userModel.storeId.isEmpty) throw Exception("Store not set up");
      
      final storeDoc = await _firestore.collection('stores').doc(userModel.storeId).get();
      final storeName = storeDoc.exists ? (storeDoc.data()?['storeName'] ?? '') : '';

      final productId = _firestore.collection('products').doc().id;
      
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final ref = _storage.ref().child('product_images/$productId/image_$i.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      final finalProduct = product.copyWith(
        productId: productId,
        storeId: userModel.storeId,
        storeName: storeName,
        images: imageUrls,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('products').doc(productId).set(finalProduct.toJson());

      // Update store products count or any other required field
      
      _isLoading = false;
      _selectedImages.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleProductVisibility(String productId, bool isActive) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Toggle visibility failed: $e");
    }
  }

  Stream<List<ProductModel>> streamProducts(String storeId) {
    return _firestore
        .collection('products')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProductModel.fromJson(doc.data())).toList());
  }
}
