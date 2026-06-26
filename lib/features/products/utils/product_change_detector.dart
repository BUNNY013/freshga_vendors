import 'package:flutter/foundation.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_variant_model.dart';

enum ProductChangeType {
  photoAdded,
  photoRemoved,
  photoReplaced,
  photoReordered,
  coverPhotoChanged,
  coverPhotoChangedApprovedImages, // Used specifically for No Review scenario

  productNameChanged,
  shortDescriptionChanged,
  fullDescriptionChanged,

  categoryChanged,
  subCategoryChanged,

  ingredientChanged,
  shelfLifeChanged,
  storageChanged,
  dispatchTimeChanged,

  variantAdded,
  variantRemoved,
  variantEdited,

  priceChanged,
  discountChanged,

  stockChanged,
  availabilityChanged,

  productArchived,
  productDeleted
}

class ProductChangeDetector {
  static List<ProductChangeType> detectProductChanges(
    ProductModel original,
    ProductModel edited,
  ) {
    List<ProductChangeType> changes = [];

    // --- PHOTOS ---
    if (!_listEquals(original.images, edited.images)) {
      final origSet = original.images.toSet();
      final editedSet = edited.images.toSet();

      bool added = editedSet.difference(origSet).isNotEmpty;
      bool removed = origSet.difference(editedSet).isNotEmpty;

      if (added && removed && original.images.length == edited.images.length) {
        changes.add(ProductChangeType.photoReplaced);
      } else {
        if (added) changes.add(ProductChangeType.photoAdded);
        if (removed) changes.add(ProductChangeType.photoRemoved);
      }

      if (!added && !removed) {
        // Same elements, just different order
        changes.add(ProductChangeType.photoReordered);
      }

      // Check Cover Photo
      if (original.images.isNotEmpty && edited.images.isNotEmpty && original.images.first != edited.images.first) {
        if (!added && origSet.contains(edited.images.first)) {
          changes.add(ProductChangeType.coverPhotoChangedApprovedImages);
        } else {
          changes.add(ProductChangeType.coverPhotoChanged);
        }
      }
    }

    // --- BASIC INFO ---
    if (original.name != edited.name) changes.add(ProductChangeType.productNameChanged);
    if (original.shortDescription != edited.shortDescription) changes.add(ProductChangeType.shortDescriptionChanged);
    if (original.description != edited.description) changes.add(ProductChangeType.fullDescriptionChanged);

    // --- CATEGORIES ---
    if (original.categoryId != edited.categoryId) changes.add(ProductChangeType.categoryChanged);
    if (!_listEquals(original.subCategoryIds, edited.subCategoryIds)) changes.add(ProductChangeType.subCategoryChanged);

    // --- OPTIONAL DETAILS ---
    if (!_listEquals(original.ingredients, edited.ingredients)) changes.add(ProductChangeType.ingredientChanged);
    if (original.shelfLife != edited.shelfLife) changes.add(ProductChangeType.shelfLifeChanged);
    if (original.storageInstructions != edited.storageInstructions) changes.add(ProductChangeType.storageChanged);
    if (original.dispatchTime != edited.dispatchTime) changes.add(ProductChangeType.dispatchTimeChanged);

    // --- PRICING ---
    if (original.price != edited.price) changes.add(ProductChangeType.priceChanged);
    if (original.originalPrice != edited.originalPrice) changes.add(ProductChangeType.discountChanged);

    // --- AVAILABILITY / STOCK ---
    if (original.isActive != edited.isActive) changes.add(ProductChangeType.availabilityChanged);
    if (original.status != edited.status && edited.status == 'Archived') changes.add(ProductChangeType.productArchived);

    // --- VARIANTS ---
    if (!_listEquals(original.variants, edited.variants)) {
      if (edited.variants.length > original.variants.length) {
        changes.add(ProductChangeType.variantAdded);
      } else if (edited.variants.length < original.variants.length) {
        changes.add(ProductChangeType.variantRemoved);
      } else {
        // Same length, assume edited
        changes.add(ProductChangeType.variantEdited);
      }
    }

    return changes;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] is ProductVariantModel && b[index] is ProductVariantModel) {
        if (!a[index].toString().contains(b[index].toString())) {
            // A simple approximation. Best to implement == on ProductVariantModel, but since we can't be sure, we do a quick check via json
            if ((a[index] as ProductVariantModel).toJson().toString() != (b[index] as ProductVariantModel).toJson().toString()) {
               return false;
            }
        }
      } else if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  /// Determines what kind of review is required based on the detected changes
  static ReviewRequirement determineReviewRequirement(List<ProductChangeType> changes) {
    if (changes.isEmpty) return ReviewRequirement.noReview;

    bool needsFullReview = false;
    bool needsLightReview = false;

    for (var change in changes) {
      switch (change) {
        // FULL REVIEW
        case ProductChangeType.photoAdded:
        case ProductChangeType.photoRemoved:
        case ProductChangeType.photoReplaced:
        case ProductChangeType.coverPhotoChanged:
        case ProductChangeType.categoryChanged:
        case ProductChangeType.subCategoryChanged:
        case ProductChangeType.variantAdded:
        case ProductChangeType.variantRemoved:
          needsFullReview = true;
          break;

        // LIGHT REVIEW
        case ProductChangeType.productNameChanged:
        case ProductChangeType.shortDescriptionChanged:
        case ProductChangeType.fullDescriptionChanged:
        case ProductChangeType.ingredientChanged:
        case ProductChangeType.shelfLifeChanged:
        case ProductChangeType.storageChanged:
        case ProductChangeType.dispatchTimeChanged:
        case ProductChangeType.priceChanged:
        case ProductChangeType.discountChanged:
        case ProductChangeType.variantEdited:
          needsLightReview = true;
          break;

        // NO REVIEW
        case ProductChangeType.photoReordered:
        case ProductChangeType.coverPhotoChangedApprovedImages:
        case ProductChangeType.stockChanged:
        case ProductChangeType.availabilityChanged:
        case ProductChangeType.productArchived:
        case ProductChangeType.productDeleted:
          // Does not trigger a review
          break;
      }
    }

    if (needsFullReview) return ReviewRequirement.fullReview;
    if (needsLightReview) return ReviewRequirement.lightReview;
    return ReviewRequirement.noReview;
  }
}

enum ReviewRequirement {
  noReview,
  lightReview,
  fullReview,
}
