import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/product_variant_model.dart';

class VendorVariantSelector extends StatelessWidget {
  final List<ProductVariantModel> variants;
  final int selectedIndex;
  final ValueChanged<int> onVariantSelected;

  const VendorVariantSelector({
    super.key,
    required this.variants,
    required this.selectedIndex,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(variants.length, (index) {
            final variant = variants[index];
            final isSelected = selectedIndex == index;

            return GestureDetector(
              onTap: () {
                onVariantSelected(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This is a preview. Variant selection is mocked."),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      variant.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
