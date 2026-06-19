import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final Function(bool) onToggleVisibility;
  final bool isListView;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onPreview,
    required this.onToggleVisibility,
    this.isListView = false,
  });

  double get _startingPrice {
    if (product.variants.isEmpty) return product.price;
    return product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  int get _totalStock => product.variants.fold(0, (sum, v) => sum + v.stock);

  bool get _isOutOfStock => product.variants.isNotEmpty && _totalStock == 0;

  @override
  Widget build(BuildContext context) {
    final bool hasMultipleVariants = product.variants.length > 1;
    final bool hasDiscount = product.originalPrice > product.price;
    final int discountPercentage = hasDiscount
        ? (((product.originalPrice - product.price) / product.originalPrice) * 100).round()
        : 0;
        
    final String sizeLabel = product.variants.isNotEmpty 
        ? product.variants.first.label 
        : product.weight;

    final isLive = product.status == 'Live';
    final isDraftOrReview = product.status == 'Draft' || product.status == 'Under Review' || product.status == 'Changes Required';
    final bool switchValue = isLive;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
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
                            color: product.tags.contains('Vegan') || product.tags.contains('Vegetarian') || product.tags.contains('Veg')
                                ? Colors.green 
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: product.tags.contains('Vegan') || product.tags.contains('Vegetarian') || product.tags.contains('Veg')
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      if (product.tags.contains("Bestseller")) ...[
                        const SizedBox(width: 8),
                        const Text(
                          "Bestseller",
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                      if (product.rating > 0) ...[
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                          ],
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
                    hasMultipleVariants 
                        ? "Starts from ${product.variants.first.label}" 
                        : sizeLabel,
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
                        "₹${_startingPrice.toStringAsFixed(0)}",
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E5), // Soft pastel orange
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$discountPercentage% OFF",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF97316), // Premium vibrant orange
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  
                  if (isDraftOrReview) ...[
                    const SizedBox(height: 12),
                    _buildStatusBadge(),
                  ]
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right Content: Image & Toggle
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
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            height: 160,
                            width: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),

                  // Action Button (Overlapping)
                  if (product.status != 'Under Review' && product.status != 'Update Under Review' && product.status != 'Submitted')
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 110,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: product.status == 'Changes Required' 
                                ? AppColors.error.withOpacity(0.3) 
                                : AppColors.primary.withOpacity(0.3), 
                            width: 1
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: product.status == 'Changes Required' ? onTap : onEdit,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.status == 'Draft' ? "CONTINUE" : 
                                    product.status == 'Changes Required' ? "REVIEW" : "MANAGE",
                                    style: TextStyle(
                                      color: product.status == 'Changes Required' 
                                          ? AppColors.error 
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 160,
      width: 160,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.fastfood_outlined, color: Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (product.status == 'Draft' || (product.status != 'Under Review' && product.status != 'Changes Required')) {
      final timeString = _getTimeAgo(product.updatedAt);
      return Text(
        'Last edited $timeString',
        style: const TextStyle(
          color: Color(0xFF64748B), // Slate grey
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    String text;
    Color dotColor;
    
    if (product.status == 'Under Review') {
      text = 'Awaiting Approval'; 
      dotColor = const Color(0xFFFF9800);
    } else {
      text = 'Changes Required'; 
      dotColor = const Color(0xFFD32F2F);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dotColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: dotColor, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String isoString) {
    if (isoString.isEmpty) return 'recently';
    try {
      final date = DateTime.parse(isoString);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 7) {
         return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }
}
