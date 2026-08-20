import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_variant_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProductPreviewSheet extends StatefulWidget {
  final ProductModel product;

  const ProductPreviewSheet({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ProductPreviewSheet(product: product),
      ),
    );
  }

  @override
  State<ProductPreviewSheet> createState() => _ProductPreviewSheetState();
}

class _ProductPreviewSheetState extends State<ProductPreviewSheet> {
  int _selectedImageIndex = 0;
  int _selectedVariantIndex = 0;

  ProductModel get product => widget.product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '👁 Customer View',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.grey600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel
                _buildImageCarousel(),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (product.shortDescription.isNotEmpty)
                        Text(
                          product.shortDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Price
                      if (product.variants.isNotEmpty)
                        _buildPriceSection(product.variants[_selectedVariantIndex]),

                      const SizedBox(height: 20),

                      // Variant Selector
                      if (product.variants.length > 1) ...[
                        const Text(
                          'Available Options',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildVariantSelector(),
                        const SizedBox(height: 20),
                      ],



                      // Description
                      if (product.description.isNotEmpty) ...[
                        const Text(
                          'About this Product',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Ingredients
                      if (product.ingredients.isNotEmpty) ...[
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: product.ingredients
                              .map((i) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(i,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Tags
                      if (product.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: product.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('#$t',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),

                // Bottom CTA preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Add to Cart — Preview Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This is how customers will see your product ✨',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    if (product.images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 280,
        color: AppColors.grey200,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 48, color: AppColors.grey400),
              SizedBox(height: 8),
              Text('No images uploaded',
                  style: TextStyle(color: AppColors.grey500, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: product.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            product.images[i],
            fit: BoxFit.cover,
            width: product.images.length > 1 ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.width - 40,
            height: 320,
            errorBuilder: (_, __, ___) => Container(
              width: product.images.length > 1 ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.width - 40,
              height: 320,
              color: AppColors.grey200,
              child: const Center(
                child: Icon(Icons.broken_image, size: 40, color: AppColors.grey400),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(ProductVariantModel variant) {
    final hasDiscount = variant.discountPrice > 0 && variant.discountPrice < variant.price;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          '₹${hasDiscount ? variant.discountPrice.toStringAsFixed(0) : variant.price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (hasDiscount) ...[
          Text(
            '₹${variant.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.grey500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${((1 - variant.discountPrice / variant.price) * 100).toStringAsFixed(0)}% off',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVariantSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(product.variants.length, (i) {
        final v = product.variants[i];
        final isSelected = i == _selectedVariantIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedVariantIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  v.label.isEmpty ? 'Default' : v.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${v.discountPrice > 0 ? v.discountPrice.toStringAsFixed(0) : v.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEngagementBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _engageStat(Icons.favorite_rounded, '${product.likes}', 'Likes',
              const Color(0xFFE57373)),
          Container(width: 1, height: 30, color: AppColors.grey300),
          _engageStat(Icons.shopping_bag_rounded, '${product.totalOrders}',
              'Orders', AppColors.primary),
          Container(width: 1, height: 30, color: AppColors.grey300),
          _engageStat(Icons.bookmark_rounded, '${product.wishlistCount}',
              'Wishlisted', const Color(0xFFFFB74D)),
        ],
      ),
    );
  }

  Widget _engageStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.grey500)),
      ],
    );
  }
}
