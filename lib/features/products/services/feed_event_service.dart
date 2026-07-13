import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/models/product_model.dart';

class FeedEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Dispatches a 'new_launch' event when a brand new product goes live for the first time.
  static Future<bool> dispatchNewLaunchEvent(ProductModel product) async {
    try {
      return await _upsertFeedEvent(
        product: product,
        type: 'new_launch',
        title: 'New Launch Alert!',
        description: 'Be the first to try our new ${product.name}!',
        badgeText: 'New',
      );
    } catch (e) {
      debugPrint("Failed to dispatch new launch event: $e");
      return false;
    }
  }

  /// Dispatches a 'restock' event when a product is made live again.
  /// Uses Silent Upsert to prevent spamming while keeping data accurate.
  static Future<bool> dispatchRestockEvent(ProductModel product) async {
    try {
      return await _upsertFeedEvent(
        product: product,
        type: 'restock',
        title: 'Back in Stock!',
        description: '${product.name} is now back in stock and ready to order.',
        badgeText: 'Restocked',
      );
    } catch (e) {
      debugPrint("Failed to dispatch restock event: $e");
      return false;
    }
  }

  /// Dispatches an 'offer' event when the price drops or a discount is added.
  /// Uses Silent Upsert to prevent spamming while keeping data accurate.
  static Future<bool> dispatchPriceDropEvent(ProductModel product, {required double oldPrice}) async {
    try {
      final currentEffectivePrice = product.price;
      // Only dispatch if it's actually cheaper
      if (currentEffectivePrice >= oldPrice) return false;

      return await _upsertFeedEvent(
        product: product,
        type: 'offer',
        title: 'Price Drop Alert!',
        description: 'Get ${product.name} at a new lower price.',
        badgeText: 'Price Drop',
      );
    } catch (e) {
      debugPrint("Failed to dispatch price drop event: $e");
      return false;
    }
  }

  /// Upserts the document in the 'store_updates' collection
  /// If a recent event exists, it updates it silently. Otherwise, creates a new one.
  static Future<bool> _upsertFeedEvent({
    required ProductModel product,
    required String type,
    required String title,
    required String description,
    required String badgeText,
  }) async {
    // Fetch store details to include logo/banner in the feed
    final storeDoc = await _firestore.collection('stores').doc(product.storeId).get();
    if (!storeDoc.exists) return false;
    
    final storeData = storeDoc.data()!;
    final storeName = storeData['storeName'] ?? product.storeName;
    final storeLogo = storeData['logo'] ?? '';
    final storeBanner = storeData['banner'] ?? '';
    
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    // Check for an existing event in the last 24 hours
    // We filter dates in-memory to avoid needing a complex composite index
    final recentEventQuery = await _firestore.collection('store_updates')
        .where('productId', isEqualTo: product.productId)
        .where('type', isEqualTo: type)
        .get();

    String? existingUpdateId;
    bool hasRecentEvent = false;

    if (recentEventQuery.docs.isNotEmpty) {
      // Find the most recent one within 24 hours
      for (var doc in recentEventQuery.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          if (createdAt.isAfter(twentyFourHoursAgo)) {
            existingUpdateId = doc.id;
            hasRecentEvent = true;
            break; // Found a recent one
          }
        }
      }
    }

    final updateId = hasRecentEvent 
        ? existingUpdateId!
        : _firestore.collection('store_updates').doc().id;

    final data = {
      'updateId': updateId,
      'storeId': product.storeId,
      'storeName': storeName,
      'storeLogo': storeLogo,
      'storeBanner': storeBanner,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': product.images.isNotEmpty ? product.images.first : '',
      'productId': product.productId,
      'productName': product.name,
      'price': product.originalPrice > 0 ? product.originalPrice : product.price,
      'discountPrice': product.originalPrice > 0 ? product.price : 0.0,
      'ctaText': 'Order Now',
      'badgeText': badgeText,
      'isActive': true,
      'createdBySeeder': false,
      'updatedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 7))),
    };

    if (hasRecentEvent) {
      // SILENT UPSERT: Update existing document, but keep original createdAt
      await _firestore.collection('store_updates').doc(updateId).update(data);
      debugPrint("Silently updated existing $type feed event for ${product.productId}");
    } else {
      // NEW INSERT: Create brand new document with fresh createdAt
      data['createdAt'] = Timestamp.fromDate(now);
      await _firestore.collection('store_updates').doc(updateId).set(data);
      debugPrint("Created NEW $type feed event for ${product.productId}");
    }

    return true;
  }
}
