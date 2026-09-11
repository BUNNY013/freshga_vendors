import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/product_model.dart';

import '../../widgets/product/vendor_product_image_section.dart';
import '../../widgets/product/vendor_variant_selector.dart';
import '../../widgets/product/vendor_product_highlights.dart';
import '../../widgets/product/vendor_ingredients_section.dart';
import '../../widgets/product/vendor_rich_store_profile_card.dart';
import '../../widgets/product/vendor_sticky_add_to_cart_bar.dart';

class VendorProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  final dynamic store; // Nullable to handle missing store info gracefully

  const VendorProductDetailsScreen({
    super.key,
    required this.product,
    this.store,
  });

  @override
  State<VendorProductDetailsScreen> createState() => _VendorProductDetailsScreenState();
}

class _VendorProductDetailsScreenState extends State<VendorProductDetailsScreen> {
  int _selectedVariantIndex = 0;

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final store = widget.store;
    
    // Calculate prices based on variant selection
    double currentPrice = product.price;
    double currentOriginalPrice = product.originalPrice;
    
    if (product.variants.isNotEmpty && _selectedVariantIndex < product.variants.length) {
      final variant = product.variants[_selectedVariantIndex];
      currentPrice = variant.discountPrice > 0 ? variant.discountPrice : variant.price;
      currentOriginalPrice = variant.discountPrice > 0 ? variant.price : currentPrice;
    }

    final hasDiscount = currentOriginalPrice > currentPrice && currentOriginalPrice > 0;
    final discount = hasDiscount 
        ? ((currentOriginalPrice - currentPrice) / currentOriginalPrice * 100).round() 
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: VendorProductImageSection(product: product),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bestseller tag
                      if (product.tags.contains("Bestseller")) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Best Seller",
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Title
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Short description
                      Text(
                        product.shortDescription.isNotEmpty 
                            ? product.shortDescription 
                            : product.weight,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${currentPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -1,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                "₹${currentOriginalPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0E5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "$discount% OFF",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF97316),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      if (product.variants.isNotEmpty) ...[
                        const Divider(height: 48, color: Color(0xFFF1F5F9)),
                        VendorVariantSelector(
                          variants: product.variants,
                          selectedIndex: _selectedVariantIndex,
                          onVariantSelected: (index) {
                            setState(() {
                              _selectedVariantIndex = index;
                            });
                          },
                        ),
                      ],
                      
                      const Divider(height: 48, color: Color(0xFFF1F5F9)),
                      
                      VendorProductHighlights(product: product),
                      
                      if (product.ingredients.isNotEmpty) ...[
                        const Divider(height: 48, color: Color(0xFFF1F5F9)),
                        VendorIngredientsSection(product: product),
                      ],
                      
                      if (store != null) ...[
                        const SizedBox(height: 24),
                        VendorRichStoreProfileCard(store: store),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Full Description
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.only(top: 8, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Product Description",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w800, 
                          color: AppColors.textPrimary
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.description.isEmpty ? "No description provided." : product.description,
                        style: const TextStyle(
                          fontSize: 15, 
                          color: AppColors.textSecondary, 
                          height: 1.6
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Sticky Add to Cart Bar
          Positioned(
            left: 0, 
            right: 0, 
            bottom: 0,
            child: VendorStickyAddToCartBar(currentPrice: currentPrice),
          ),
          
          // Top Actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preview mode: Share disabled')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildGlassButton(
                      icon: Icons.favorite_border,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preview mode: Wishlist disabled')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
