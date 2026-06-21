import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/sub_category_model.dart';

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

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  List<SubCategoryModel> _subCategories = [];
  List<SubCategoryModel> get subCategories => _subCategories;

  Future<void> loadCategories() async {
    try {
      final snapshot = await _firestore.collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      List<CategoryModel> loaded = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['categoryId'] ??= doc.id;
          final loadedCat = CategoryModel.fromJson(data);
          loaded.add(loadedCat);
          if (loaded.length <= 3) {
            debugPrint("Loaded Category: name=${loadedCat.name}, categoryId=${loadedCat.categoryId}, docId=${doc.id}");
          }
        } catch (e) {
          debugPrint("Failed to parse category ${doc.id}: $e");
        }
      }
      _categories = loaded;
      debugPrint("Successfully loaded ${_categories.length} categories from Firebase.");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load categories: $e");
    }
  }

  Future<void> loadSubCategories(String categoryId) async {
    try {
      final snapshot = await _firestore.collection('sub_categories')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      List<SubCategoryModel> loaded = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['subCategoryId'] ??= doc.id;
          loaded.add(SubCategoryModel.fromJson(data));
        } catch (e) {
          debugPrint("Failed to parse subcategory ${doc.id}: $e");
        }
      }
      _errorMessage = null;
      _subCategories = loaded;
      debugPrint("Successfully loaded ${_subCategories.length} subcategories from Firebase for category $categoryId.");
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to load subcategories: $e";
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

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

  Future<ProductModel?> addProduct(ProductModel product) async {
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
      
      List<Future<String>> uploadTasks = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final ref = _storage.ref().child('product_images/$productId/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        uploadTasks.add(ref.putFile(file).then((snapshot) => snapshot.ref.getDownloadURL()));
      }
      List<String> imageUrls = await Future.wait(uploadTasks);

      final finalProduct = product.copyWith(
        productId: productId,
        storeId: userModel.storeId,
        storeName: storeName,
        images: imageUrls,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('products').doc(productId).set(finalProduct.toJson());

      _isLoading = false;
      _selectedImages.clear();
      notifyListeners();
      return finalProduct;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateFullProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("Not authenticated");

      // Handle newly selected images
      List<String> imageUrls = List.from(product.images);
      
      List<Future<String>> uploadTasks = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final ref = _storage.ref().child('product_images/${product.productId}/image_new_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        uploadTasks.add(ref.putFile(file).then((snapshot) => snapshot.ref.getDownloadURL()));
      }
      
      final newImageUrls = await Future.wait(uploadTasks);
      imageUrls.addAll(newImageUrls);

      final finalProduct = product.copyWith(
        images: imageUrls,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('products').doc(product.productId).update(finalProduct.toJson());

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
        'status': isActive ? 'Live' : 'Hidden',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Toggle visibility failed: $e");
    }
  }

  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': status,
        'isActive': status == 'Live',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Update status failed: $e");
    }
  }

  Future<bool> updateOperationalFields(String productId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('products').doc(productId).update(updates);
      return true;
    } catch (e) {
      debugPrint("Update operational failed: $e");
      return false;
    }
  }

  Future<bool> updateDraftContent(ProductModel currentProduct, Map<String, dynamic> draftUpdates, {String? clearRequiredFix}) async {
    _isLoading = true;
    notifyListeners();
    try {
      List<String> newRequiredFixes = List.from(currentProduct.requiredFixes);
      if (clearRequiredFix != null) {
        newRequiredFixes.remove(clearRequiredFix);
      }

      Map<String, dynamic> firestoreUpdates = {
        'requiredFixes': newRequiredFixes,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (currentProduct.lastApprovedAt == null) {
         // Product has NEVER been live. Update the flat fields directly.
         firestoreUpdates.addAll(draftUpdates);
      } else {
         // Product is or was Live. Save changes to draftVersion.
         final currentDraft = currentProduct.draftVersion ?? {};
         final newDraft = Map<String, dynamic>.from(currentDraft)..addAll(draftUpdates);
         
         String newStatus = currentProduct.status;
         if (currentProduct.status == 'Live') {
           newStatus = 'Live + Draft Changes';
         }
         
         firestoreUpdates['draftVersion'] = newDraft;
         firestoreUpdates['status'] = newStatus;
      }
      
      await _firestore.collection('products').doc(currentProduct.productId).update(firestoreUpdates);
      
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

  Future<bool> submitDraftForReview(ProductModel currentProduct) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (currentProduct.requiredFixes.isNotEmpty) {
        throw Exception("Cannot submit: outstanding required fixes must be addressed.");
      }
      
      final draft = currentProduct.draftVersion;
      if (currentProduct.lastApprovedAt == null || draft == null || draft.isEmpty) {
         // New product or no draft overrides
         await _firestore.collection('products').doc(currentProduct.productId).update({
           'status': 'Under Review',
           'lastSubmittedAt': DateTime.now().toIso8601String(),
           'updatedAt': DateTime.now().toIso8601String(),
         });
      } else {
        // Has a draft version to submit
        String newStatus = currentProduct.status.startsWith('Live') || currentProduct.status == 'Changes Required' 
            ? 'Live + Update Pending' 
            : 'Under Review';
        
        await _firestore.collection('products').doc(currentProduct.productId).update({
          'pendingReviewVersion': draft,
          'status': newStatus,
          'lastSubmittedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
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

  Future<bool> withdrawSubmission(ProductModel currentProduct) async {
    _isLoading = true;
    notifyListeners();
    try {
      String newStatus = 'Draft';
      if (currentProduct.status == 'Live + Update Pending') {
         newStatus = 'Live + Draft Changes';
      }
      
      await _firestore.collection('products').doc(currentProduct.productId).update({
        'pendingReviewVersion': FieldValue.delete(),
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
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

  Future<bool> duplicateProduct(ProductModel product) async {
    try {
      final newId = _firestore.collection('products').doc().id;
      final dup = product.copyWith(
        productId: newId,
        name: '${product.name} (Copy)',
        status: 'Draft',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _firestore.collection('products').doc(newId).set(dup.toJson());
      return true;
    } catch (e) {
      debugPrint("Duplicate product failed: $e");
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      // Delete product images from storage
      try {
        final listResult = await _storage.ref().child('product_images/$productId').listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
      } catch (_) {
        // Images may not exist, continue
      }

      // Delete product document
      await _firestore.collection('products').doc(productId).delete();
      return true;
    } catch (e) {
      debugPrint("Delete product failed: $e");
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = product.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _firestore.collection('products').doc(product.productId).update(updated.toJson());

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

  Stream<List<ProductModel>> streamProducts(String storeId) {
    return _firestore
        .collection('products')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProductModel.fromJson(doc.data())).toList());
  }
}
