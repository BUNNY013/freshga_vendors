import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/product_model.dart';
import '../../../../../data/models/store_model.dart';
import '../screens/preview/vendor_product_details_screen.dart';

class VendorStoreProductListItem extends StatelessWidget {
  final ProductModel product;
  final StoreModel store;

  const VendorStoreProductListItem({super.key, required this.product, required this.store});

  @override
  Widget build(BuildContext context) {
    // Determine if there is a discount in the vendor model
    final bool hasDiscount = product.originalPrice > product.price;
    final int discountPercentage = hasDiscount
        ? (((product.originalPrice - product.price) / product.originalPrice) * 100).round()
        : 0;

    final String displayPrice = "₹${product.price.toStringAsFixed(0)}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorProductDetailsScreen(
              product: product,
              store: store,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Content: Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Veg/Non-Veg Tag & Rating
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: product.tags.contains('Vegan') ||
                                  product.tags.contains('Vegetarian') ||
                                  product.tags.contains('Veg')
                              ? Colors.green
                              : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: product.tags.contains('Vegan') ||
                                product.tags.contains('Vegetarian') ||
                                product.tags.contains('Veg')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (product.tags.contains("Bestseller")) ...[
                      const SizedBox(width: 8),
                      const Text(
                        "Bestseller",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Quantity / Size
                Text(
                  product.weight,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Pricing Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            "₹${product.originalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8), // Premium slate grey
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFF0E5,
                              ), // Soft pastel orange
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$discountPercentage% OFF",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(
                                  0xFFF97316,
                                ), // Premium vibrant orange
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Content: Image & Add Button
          SizedBox(
            width: 160,
            height: 184,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty ? product.images.first : '',
                    height: 160,
                    width: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),

                // Add Button (Disabled for Preview)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 110,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("This is a preview. Cart actions are disabled."),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "ADD",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.add,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // End of Stack
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
