import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../products/presentation/providers/product_provider.dart';

class VendorDynamicCategoryChips extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const VendorDynamicCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<VendorDynamicCategoryChips> createState() =>
      _VendorDynamicCategoryChipsState();
}

class _VendorDynamicCategoryChipsState
    extends State<VendorDynamicCategoryChips> {
  final ScrollController _scrollController = ScrollController();
  String _lastSelected = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.categories.isEmpty) {
        provider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    // Listen to ProductProvider so we rebuild when categories are loaded
    final productProvider = Provider.of<ProductProvider>(context);

    final items = ['All', ...widget.categories];

    if (_lastSelected != widget.selectedCategory) {
      _lastSelected = widget.selectedCategory;
      final index = items.indexOf(_lastSelected);
      if (index != -1 && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            double offset = (index * 92.0) -
                (MediaQuery.of(context).size.width / 2) +
                46.0;
            if (offset < 0) offset = 0;
            if (offset > _scrollController.position.maxScrollExtent) {
              offset = _scrollController.position.maxScrollExtent;
            }
            _scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }

    return SizedBox(
      height: 112, // Increased for bigger, premium circles
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final cat = items[index];
          final isSelected = widget.selectedCategory == cat;

          String? imageUrl;
          if (cat != 'All') {
            try {
              final categoryModel = productProvider.categories.firstWhere(
                (c) => c.name.toLowerCase() == cat.toLowerCase()
              );
              imageUrl = categoryModel.imageUrl;
            } catch (e) {
              // Image not found
            }
          }

          return GestureDetector(
            onTap: () => widget.onCategorySelected(cat),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: SizedBox(
                width: 80, // Wider for bigger circles
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: ClipOval(
                        child: cat == 'All'
                            ? Icon(
                                Icons.grid_view,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 32,
                              )
                            : (imageUrl != null && imageUrl.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.fastfood_outlined,
                                      color: isSelected ? AppColors.primary : Colors.grey,
                                      size: 32,
                                    ),
                                  )
                                : Icon(
                                    Icons.fastfood_outlined,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey,
                                    size: 32,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2, // Tighter line height for 2 lines
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
