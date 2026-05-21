import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';

class ProductActionsSheet extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const ProductActionsSheet({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onPreview,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  static void show(
    BuildContext context, {
    required ProductModel product,
    required VoidCallback onEdit,
    required VoidCallback onPreview,
    required VoidCallback onToggleVisibility,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => ProductActionsSheet(
        product: product,
        onEdit: onEdit,
        onPreview: onPreview,
        onToggleVisibility: onToggleVisibility,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Product preview header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? const Color(0xFF4CAF50)
                                  : AppColors.grey500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isActive ? 'Live' : 'Hidden',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.isActive
                                  ? const Color(0xFF4CAF50)
                                  : AppColors.grey500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.variants.length} variants',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 8),

            // Actions
            _buildAction(
              icon: Icons.edit_outlined,
              label: 'Edit Product',
              subtitle: 'Update details, images, variants',
              color: AppColors.textPrimary,
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            _buildAction(
              icon: Icons.remove_red_eye_outlined,
              label: 'Preview as Customer',
              subtitle: 'See how your product looks to buyers',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                onPreview();
              },
            ),
            _buildAction(
              icon: product.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: product.isActive ? 'Hide Product' : 'Make Live',
              subtitle: product.isActive
                  ? 'Temporarily hide from customers'
                  : 'Show product to customers again',
              color: product.isActive
                  ? AppColors.grey600
                  : const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                onToggleVisibility();
              },
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 4),
            _buildAction(
              icon: Icons.delete_outline,
              label: 'Delete Product',
              subtitle: 'Permanently remove this product',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.grey600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(Icons.fastfood_outlined, color: AppColors.grey400, size: 24),
      ),
    );
  }
}
