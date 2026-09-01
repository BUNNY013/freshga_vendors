import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/sub_category_model.dart';
import '../../utils/product_change_detector.dart';
import '../../services/feed_event_service.dart';

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

  final Map<String, List<SubCategoryModel>> _subCategoryCache = {};
  static List<CategoryModel>? _cachedCategories;
  static final Map<String, List<SubCategoryModel>> _staticSubCategoryCache = {};

  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _cachedCategories!.isNotEmpty) {
      _categories = _cachedCategories!;
      notifyListeners();
      return;
    }
    try {
      final snapshot = await _firestore.collection('categories').get();
      List<CategoryModel> loaded = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['categoryId'] ??= doc.id;
          final loadedCat = CategoryModel.fromJson(data);
          if (loadedCat.isActive) {
            loaded.add(loadedCat);
          }
        } catch (e) {
          debugPrint("Failed to parse category ${doc.id}: $e");
        }
      }
      loaded.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _categories = loaded;
      _cachedCategories = loaded;
      debugPrint("Successfully loaded ${_categories.length} active categories from Firebase.");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load categories: $e");
    }
  }

  Future<void> loadSubCategories(String categoryId) async {
    // 1. Instant Cache Check for lightning-fast UI loading
    if (_subCategoryCache.containsKey(categoryId)) {
      _errorMessage = null;
      _subCategories = List.from(_subCategoryCache[categoryId]!);
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (_staticSubCategoryCache.containsKey(categoryId)) {
      _errorMessage = null;
      _subCategories = List.from(_staticSubCategoryCache[categoryId]!);
      _subCategoryCache[categoryId] = _subCategories;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 2. Clear previous category's subcategories immediately and show loading spinner
    _isLoading = true;
    _subCategories = [];
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('sub_categories')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      List<SubCategoryModel> loaded = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['subCategoryId'] ??= doc.id;
          final loadedSub = SubCategoryModel.fromJson(data);
          if (loadedSub.isActive) {
            loaded.add(loadedSub);
          }
        } catch (e) {
          debugPrint("Failed to parse subcategory ${doc.id}: $e");
        }
      }
      loaded.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _errorMessage = null;
      _subCategories = loaded;
      _subCategoryCache[categoryId] = loaded;
      _staticSubCategoryCache[categoryId] = loaded;
      debugPrint("Successfully loaded ${_subCategories.length} active subcategories from Firebase for category $categoryId.");
    } catch (e) {
      _errorMessage = "Failed to load subcategories: $e";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      for (var xFile in picked) {
        if (_selectedImages.length >= 10) break;
        final isCover = _selectedImages.isEmpty;
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: xFile.path,
          maxWidth: 1080,
          maxHeight: 1080,
          compressQuality: 80,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: isCover ? 'Crop Cover Photo (1:1)' : 'Crop Product Photo (1:1)',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: isCover ? 'Crop Cover Photo (1:1)' : 'Crop Product Photo (1:1)',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          _selectedImages.add(File(croppedFile.path));
          notifyListeners();
        }
      }
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

  static String? _cachedStoreId;
  static String? _cachedStoreName;

  Future<void> _ensureStoreInfoLoaded() async {
    if (_cachedStoreId != null && _cachedStoreName != null && _cachedStoreId!.isNotEmpty) {
      return;
    }
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userModel = UserModel.fromJson(userDoc.data()!);
    if (userModel.storeId.isEmpty) throw Exception("Store not set up");
      
    final storeDoc = await _firestore.collection('stores').doc(userModel.storeId).get();
    _cachedStoreId = userModel.storeId;
    _cachedStoreName = storeDoc.exists ? (storeDoc.data()?['storeName'] ?? '') : '';
  }

  Future<ProductModel?> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureStoreInfoLoaded();

      final productId = _firestore.collection('products').doc().id;
      
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        List<Future<String>> uploadTasks = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          final file = _selectedImages[i];
          final ref = _storage.ref().child('product_images/$productId/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          uploadTasks.add(ref.putFile(file).then((snapshot) => snapshot.ref.getDownloadURL()));
        }
        
        try {
          imageUrls = await Future.wait(uploadTasks)
              .timeout(const Duration(seconds: 25));
        } catch (e) {
          if (product.status == 'Draft') {
            // Gracefully ignore image upload failure for drafts so they don't lose text data
            debugPrint("Image upload failed for draft: $e");
          } else {
            throw Exception('Image upload timed out. Please check your network and try again.');
          }
        }
      }

      final finalProduct = product.copyWith(
        productId: productId,
        storeId: _cachedStoreId!,
        storeName: _cachedStoreName!,
        images: imageUrls,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('products').doc(productId).set(finalProduct.toJson())
          .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while creating product. Please check your network.'));

      if (_cachedStoreId != null) {
        await _firestore.collection('stores').doc(_cachedStoreId).update({
          'productsCount': FieldValue.increment(1),
        });
      }

      _selectedImages.clear();
      return finalProduct;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFullProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("Not authenticated");

      // Check for price drop before update
      final oldDoc = await _firestore.collection('products').doc(product.productId).get()
          .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out. Please check your network.'));
      if (oldDoc.exists) {
        final oldProduct = ProductModel.fromJson(oldDoc.data()!);
        final oldEffectivePrice = oldProduct.price;
        await FeedEventService.dispatchPriceDropEvent(product, oldPrice: oldEffectivePrice);
      }

      // Handle newly selected images
      List<String> imageUrls = List.from(product.images);
      
      if (_selectedImages.isNotEmpty) {
        List<Future<String>> uploadTasks = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          final file = _selectedImages[i];
          final ref = _storage.ref().child('product_images/${product.productId}/image_new_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          uploadTasks.add(ref.putFile(file).then((snapshot) => snapshot.ref.getDownloadURL()));
        }
        
        try {
          final newImageUrls = await Future.wait(uploadTasks)
              .timeout(const Duration(seconds: 25));
          imageUrls.addAll(newImageUrls);
        } catch (e) {
          if (product.status == 'Draft') {
            debugPrint("Image upload failed for draft update: $e");
          } else {
            throw Exception('Image upload timed out. Please check your network and try again.');
          }
        }
      }

      final finalProduct = product.copyWith(
        images: imageUrls,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('products').doc(product.productId).update(finalProduct.toJson())
          .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while updating product. Please check your network.'));

      _selectedImages.clear();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleProductVisibility(String productId, bool isActive) async {
    try {
      if (isActive) {
        final doc = await _firestore.collection('products').doc(productId).get();
        if (doc.exists) {
          final p = ProductModel.fromJson(doc.data()!);
          if (!p.isActive) {
            if (p.status == 'Approved') {
              FeedEventService.dispatchNewLaunchEvent(p);
            } else {
              FeedEventService.dispatchRestockEvent(p);
            }
          }
        }
      }
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
      if (status.startsWith('Live')) {
        final doc = await _firestore.collection('products').doc(productId).get();
        if (doc.exists) {
          final p = ProductModel.fromJson(doc.data()!);
          if (!p.isActive) {
            if (p.status == 'Approved') {
              FeedEventService.dispatchNewLaunchEvent(p);
            } else {
              FeedEventService.dispatchRestockEvent(p);
            }
          }
        }
      }
      await _firestore.collection('products').doc(productId).update({
        'status': status,
        'isActive': status.startsWith('Live'),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Update status failed: $e");
    }
  }

  Future<bool> cancelPendingUpdate(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': 'Live',
        'pendingReviewVersion': FieldValue.delete(),
        'pendingUpdate': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Cancel pending update failed: $e");
      return false;
    }
  }

  Future<bool> updateOperationalFields(String productId, Map<String, dynamic> updates, {String? clearRequiredFix}) async {
    _errorMessage = null;
    try {
      if (clearRequiredFix != null) {
        final doc = await _firestore.collection('products').doc(productId).get()
            .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out. Please check your network.'));
        if (doc.exists) {
          List<String> fixes = List<String>.from(doc.data()!['requiredFixes'] ?? []);
          if (fixes.contains(clearRequiredFix)) {
            fixes.remove(clearRequiredFix);
            updates['requiredFixes'] = fixes;
          }
          Map<String, dynamic> feedbackMap = Map<String, dynamic>.from(doc.data()!['reviewFeedback'] ?? {});
          if (feedbackMap.containsKey(clearRequiredFix)) {
            final sectionMap = Map<String, dynamic>.from(feedbackMap[clearRequiredFix] ?? {});
            sectionMap['status'] = 'fixed';
            feedbackMap[clearRequiredFix] = sectionMap;
            updates['reviewFeedback'] = feedbackMap;
          }
        }
      }

      if (updates.containsKey('price')) {
        final doc = await _firestore.collection('products').doc(productId).get()
            .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out. Please check your network.'));
        if (doc.exists) {
          final oldProduct = ProductModel.fromJson(doc.data()!);
          final oldEffectivePrice = oldProduct.price;
          
          final newJson = Map<String, dynamic>.from(doc.data()!);
          newJson.addAll(updates);
          final newProduct = ProductModel.fromJson(newJson);
          
          await FeedEventService.dispatchPriceDropEvent(newProduct, oldPrice: oldEffectivePrice);
        }
      }

      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('products').doc(productId).update(updates)
          .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while updating pricing. Please check your network.'));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Update operational failed: $e");
      return false;
    }
  }

  Future<ReviewRequirement?> updateDraftContent(ProductModel currentProduct, Map<String, dynamic> draftUpdates, {String? clearRequiredFix}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      List<String> newRequiredFixes = List.from(currentProduct.requiredFixes);
      Map<String, dynamic> newReviewFeedback = Map<String, dynamic>.from(currentProduct.reviewFeedback ?? {});
      if (clearRequiredFix != null) {
        newRequiredFixes.remove(clearRequiredFix);
        if (newReviewFeedback.containsKey(clearRequiredFix)) {
          final sectionMap = Map<String, dynamic>.from(newReviewFeedback[clearRequiredFix] ?? {});
          sectionMap['status'] = 'fixed';
          newReviewFeedback[clearRequiredFix] = sectionMap;
        }
      }

      Map<String, dynamic> firestoreUpdates = {
        'requiredFixes': newRequiredFixes,
        'reviewFeedback': newReviewFeedback,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (currentProduct.status == 'Changes Required') {
        // Vendor is saving edits to a section while addressing review feedback.
        // DO NOT change status! Keep it in Changes Required until they explicitly resubmit.
        bool wasLiveBefore = currentProduct.lastApprovedAt != null || currentProduct.status.startsWith('Live');
        if (!wasLiveBefore) {
          // Pure new product never approved: save edits directly to product fields
          firestoreUpdates.addAll(draftUpdates);
        } else {
          // Was previously live: save edits into pendingReviewVersion so live product fields remain untouched
          final currentPending = currentProduct.pendingReviewVersion ?? currentProduct.draftVersion ?? {};
          final newPending = Map<String, dynamic>.from(currentPending)..addAll(draftUpdates);
          firestoreUpdates['pendingReviewVersion'] = newPending;
        }
        await _firestore.collection('products').doc(currentProduct.productId).update(firestoreUpdates)
            .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while saving changes. Please check your network.'));
        return ReviewRequirement.fullReview;
      }

      bool isLiveOrWasLive = currentProduct.lastApprovedAt != null || currentProduct.status.startsWith('Live');
      
      if (!isLiveOrWasLive) {
         // Product is a pure Draft. Auto-submit since vendors don't manage drafts manually.
         firestoreUpdates.addAll(draftUpdates);
         firestoreUpdates['status'] = 'Under Review';
         firestoreUpdates['lastSubmittedAt'] = DateTime.now().toIso8601String();
      } else {
         // Product is or was Live, or is responding to feedback.
         // Build the edited version combining current live data + existing drafts + new draft updates
         final currentDraft = currentProduct.draftVersion ?? {};
         final newDraft = Map<String, dynamic>.from(currentDraft)..addAll(draftUpdates);
         
         final editedJson = currentProduct.toJson()..addAll(newDraft);
         final editedProduct = ProductModel.fromJson(editedJson);
         
         final changes = ProductChangeDetector.detectProductChanges(currentProduct, editedProduct);
         final reviewRequirement = ProductChangeDetector.determineReviewRequirement(changes);

         if (reviewRequirement == ReviewRequirement.noReview) {
            // Apply immediately to the live product flat fields
            firestoreUpdates.addAll(newDraft);
            firestoreUpdates['draftVersion'] = FieldValue.delete();
            
            if (currentProduct.status == 'Live + Draft Changes') {
               firestoreUpdates['status'] = 'Live';
            }
         } else {
            // Needs review. Auto-submit as Product Update since it's a live product.
            String newStatus = currentProduct.status.startsWith('Live') || (currentProduct.lastApprovedAt != null && currentProduct.status == 'Changes Required')
                ? 'Live + Update Pending'
                : 'Under Review';
                
            firestoreUpdates['pendingReviewVersion'] = newDraft;
            firestoreUpdates['status'] = newStatus;
            firestoreUpdates['lastSubmittedAt'] = DateTime.now().toIso8601String();
            firestoreUpdates['draftVersion'] = FieldValue.delete();
         }
      }
      
      await _firestore.collection('products').doc(currentProduct.productId).update(firestoreUpdates)
          .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while saving changes. Please check your network.'));
      
      if (!isLiveOrWasLive) {
        return ReviewRequirement.fullReview;
      }
      final currentDraft = currentProduct.draftVersion ?? {};
      final newDraft = Map<String, dynamic>.from(currentDraft)..addAll(draftUpdates);
      final editedJson = currentProduct.toJson()..addAll(newDraft);
      final editedProduct = ProductModel.fromJson(editedJson);
      final changes = ProductChangeDetector.detectProductChanges(currentProduct, editedProduct);
      return ProductChangeDetector.determineReviewRequirement(changes);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDraftForReview(ProductModel currentProduct) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (currentProduct.status == 'Changes Required') {
        final doc = await _firestore.collection('products').doc(currentProduct.productId).get();
        final currentFixes = doc.exists ? List<String>.from(doc.data()!['requiredFixes'] ?? []) : currentProduct.requiredFixes;
        if (currentFixes.isNotEmpty) {
          _errorMessage = 'Please fix all required changes before resubmitting. Remaining: ${currentFixes.join(", ")}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      bool isNewProduct = currentProduct.lastApprovedAt == null && !currentProduct.status.startsWith('Live');
      if (isNewProduct) {
         Map<String, dynamic> updates = {
           'status': 'Under Review',
           'requiredFixes': [],
           'reviewFeedback': {},
           'lastSubmittedAt': DateTime.now().toIso8601String(),
           'updatedAt': DateTime.now().toIso8601String(),
         };
         if (currentProduct.pendingReviewVersion != null && currentProduct.pendingReviewVersion!.isNotEmpty) {
           updates.addAll(currentProduct.pendingReviewVersion!);
           updates['pendingReviewVersion'] = FieldValue.delete();
         }
         if (currentProduct.draftVersion != null && currentProduct.draftVersion!.isNotEmpty) {
           updates.addAll(currentProduct.draftVersion!);
           updates['draftVersion'] = FieldValue.delete();
         }
         await _firestore.collection('products').doc(currentProduct.productId).update(updates)
             .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while resubmitting product. Please check your network.'));
      } else {
         // Has a draft/pending version to submit for a Live product
         final draft = currentProduct.draftVersion ?? currentProduct.pendingReviewVersion;
         String newStatus = 'Live + Update Pending';
         Map<String, dynamic> updates = {
           'status': newStatus,
           'requiredFixes': [],
           'reviewFeedback': {},
           'lastSubmittedAt': DateTime.now().toIso8601String(),
           'updatedAt': DateTime.now().toIso8601String(),
         };
         if (draft != null) {
           updates['pendingReviewVersion'] = draft;
         }
         await _firestore.collection('products').doc(currentProduct.productId).update(updates)
             .timeout(const Duration(seconds: 12), onTimeout: () => throw TimeoutException('Connection timed out while resubmitting product. Please check your network.'));
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> withdrawSubmission(ProductModel currentProduct) async {
    _isLoading = true;
    notifyListeners();
    try {
      String newStatus = 'Draft';
      if (currentProduct.lastApprovedAt != null || 
          currentProduct.status.startsWith('Live') || 
          currentProduct.status == 'Update Under Review' || 
          currentProduct.status == 'Changes Required') {
         newStatus = 'Live';
      }
      
      await _firestore.collection('products').doc(currentProduct.productId).update({
        'pendingReviewVersion': FieldValue.delete(),
        'pendingUpdate': FieldValue.delete(),
        'reviewFeedback': FieldValue.delete(),
        'requiredFixes': FieldValue.delete(),
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
        
        if (_cachedStoreId != null) {
          await _firestore.collection('stores').doc(_cachedStoreId).update({
            'productsCount': FieldValue.increment(1),
          });
        }
        
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
        
        if (_cachedStoreId != null) {
          await _firestore.collection('stores').doc(_cachedStoreId).update({
            'productsCount': FieldValue.increment(-1),
          });
        }
        
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
      // Check for price drop before update
      final oldDoc = await _firestore.collection('products').doc(product.productId).get();
      if (oldDoc.exists) {
        final oldProduct = ProductModel.fromJson(oldDoc.data()!);
        final oldEffectivePrice = oldProduct.price;
        await FeedEventService.dispatchPriceDropEvent(product, oldPrice: oldEffectivePrice);
      }

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
