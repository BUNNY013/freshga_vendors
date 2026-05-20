import 'package:flutter/material.dart';
import '../../../../data/models/product_variant_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class VariantCard extends StatelessWidget {
  final ProductVariantModel variant;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<bool> onAvailabilityToggle;

  const VariantCard({
    super.key,
    required this.variant,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onAvailabilityToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  variant.label.isEmpty ? 'New Variant' : variant.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Switch(
                    value: variant.isAvailable,
                    onChanged: onAvailabilityToggle,
                    activeColor: AppColors.primary,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'duplicate') onDuplicate();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('₹${variant.price.toStringAsFixed(0)}', style: AppTextStyles.h3),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discount Price', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      variant.discountPrice > 0 ? '₹${variant.discountPrice.toStringAsFixed(0)}' : '-',
                      style: AppTextStyles.h3.copyWith(color: Colors.green),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stock', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${variant.stock}', style: AppTextStyles.h3),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Variant'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
