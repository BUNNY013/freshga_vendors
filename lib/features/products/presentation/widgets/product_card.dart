import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final Function(bool) onToggleVisibility;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate starting price
    double startingPrice = 0;
    if (product.variants.isNotEmpty) {
      startingPrice = product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
    }
    
    // Total stock
    int totalStock = product.variants.fold(0, (sum, v) => sum + v.stock);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? Colors.green.withOpacity(0.9)
                          : AppColors.grey500.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isActive ? 'Active' : 'Hidden',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Details Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  startingPrice > 0 ? "From ₹${startingPrice.toStringAsFixed(0)}" : "Price TBA",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.style_outlined, size: 14, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Text(
                          "${product.variants.length} Variants",
                          style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Text(
                          "$totalStock left",
                          style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(
                          "${product.likes}",
                          style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          "${product.totalOrders}",
                          style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text("Edit", style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 20, color: AppColors.grey200),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => onToggleVisibility(!product.isActive),
                        icon: Icon(
                          product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                        ),
                        label: Text(
                          product.isActive ? "Hide" : "Publish",
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: product.isActive ? AppColors.grey600 : AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(Icons.fastfood_outlined, color: AppColors.grey400, size: 32),
      ),
    );
  }
}
