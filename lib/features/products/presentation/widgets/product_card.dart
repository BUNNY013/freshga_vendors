import 'package:flutter/material.dart';
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
  final bool isLiveSection;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onPreview,
    required this.onToggleVisibility,
    this.isListView = false,
    this.isLiveSection = false,
  });

  String get _priceRange {
    if (product.variants.isEmpty) return "₹${product.price.toStringAsFixed(0)}";
    if (product.variants.length == 1) return "₹${product.variants.first.price.toStringAsFixed(0)}";
    double minPrice = product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
    double maxPrice = product.variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
    if (minPrice == maxPrice) return "₹${minPrice.toStringAsFixed(0)}";
    return "₹${minPrice.toStringAsFixed(0)} - ₹${maxPrice.toStringAsFixed(0)}";
  }

  bool get _hasDraftChanges => product.draftVersion != null && product.draftVersion!.isNotEmpty;
  bool get _isUpdatePending => product.status == 'Update Under Review' || product.pendingReviewVersion != null || product.pendingUpdate != null;

  VoidCallback get _cardAction {
    if (isLiveSection) {
      return onTap;
    }
    if (product.status == 'Under Review' || product.status == 'Submitted' || product.status == 'Update Under Review' || product.status == 'Changes Required' || product.status == 'Draft' || product.status == 'Unavailable' || product.status == 'Live + Update Pending') {
      return onTap;
    }
    return onEdit;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cardAction,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(),
                const SizedBox(width: 16),
                Expanded(child: _buildProductDetails()),
              ],
            ),
            _buildActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: _buildStatusBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 96,
      width: 96,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.fastfood_outlined, color: Color(0xFF64748B), size: 32),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Name + Preview Icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Category Path and Time
        Row(
          children: [
            Expanded(
              child: Text(
                product.categoryName.isNotEmpty ? product.categoryName : 'Uncategorized',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (product.status != 'Live') ...[
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const SizedBox(width: 8),
              Text(
                (product.status == 'Under Review' || product.status == 'Submitted' || product.status == 'Update Under Review') 
                  ? 'Submitted ${_getTimeAgo(product.updatedAt)}'
                  : 'Edited ${_getTimeAgo(product.updatedAt)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Price Range
        Text(
          _priceRange,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800, // ExtraBold
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Chips
        if (product.variants.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${product.variants.length} Variants',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500, // Medium
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Stats
        if (product.status == 'Live' || isLiveSection || product.status.startsWith('Live') || product.lastApprovedAt != null) ...[
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text('${product.likes} Likes', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(width: 16),
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text('${product.totalOrders} Orders', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ],
        
        // Other statuses dynamic content
        if (product.status != 'Live' || _hasDraftChanges || _isUpdatePending)
          _buildDynamicContent(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bgColor;

    if (isLiveSection || product.status == 'Live' || product.status.startsWith('Live') || product.status == 'Approved') {
      text = 'LIVE';
      bgColor = const Color(0xFF16A34A);
    } else if (product.status == 'Changes Required') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'CHANGES REQ.',
            style: TextStyle(color: Color(0xFFE11D48), fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      );
    } else if (product.status == 'Draft') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'DRAFT',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    } else if (product.status == 'Under Review' || product.status == 'Update Under Review' || product.status == 'Submitted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF97316).withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFF97316).withOpacity(0.2)),
        ),
        child: const Text(
          'UNDER REVIEW',
          style: TextStyle(color: Color(0xFFF97316), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      );
    } else if (product.status == 'Approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.2)),
        ),
        child: const Text(
          'APPROVED & READY',
          style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      );
    } else if (product.status == 'Unavailable') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'UNAVAILABLE',
          style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      text = product.status.toUpperCase();
      bgColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDynamicContent() {
    if (product.status == 'Changes Required') {
      if (isLiveSection) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Color(0xFFE11D48)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Go to Changes Req. section to fix update issues',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE11D48),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.requiredFixes.map((issue) {
                return Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            issue,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Fix Issues', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    } else if (!isLiveSection && (product.status == 'Under Review' || product.status == 'Submitted' || product.status == 'Update Under Review' || product.status == 'Live + Update Pending' || product.pendingUpdate != null || product.pendingReviewVersion != null)) {
      return const SizedBox();
    } else if (product.status == 'Live' || (isLiveSection && product.status.startsWith('Live'))) {
      if (_hasDraftChanges) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSmallBadge('DRAFT CHANGES', Colors.orange),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Unsaved Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
            const SizedBox(height: 2),
            Text('Last edited ${_getTimeAgo(product.updatedAt)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        );
      } else if (_isUpdatePending) {
         return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSmallBadge('UPDATE PENDING', const Color(0xFF3B82F6)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Customers currently see the approved version.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            const Text('Your latest updates are under review.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ],
        );
      }
    } else if (product.status == 'Approved') {
       return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Your product has been approved by the Admin!', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Publish it to notify your followers and go live.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      );
    } else if (product.status == 'Update Under Review') {
       return const SizedBox();
    } else if (product.status == 'Draft') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Continue Editing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    } else if (product.status == 'Unavailable') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    } else if (product.status == 'Hidden') {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Paused By Vendor',
          style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildActionArea() {
    if (product.status == 'Changes Required') {
      return const SizedBox();
    } else if (!isLiveSection && (product.status == 'Under Review' || product.status == 'Submitted' || product.status == 'Update Under Review' || product.status == 'Live + Update Pending')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF97316),
              side: const BorderSide(color: Color(0xFFF97316), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('View Review Status', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ),
      );
    } else if ((product.status == 'Live' || (isLiveSection && product.status.startsWith('Live'))) && _hasDraftChanges) {
       return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton(
            onPressed: onTap, // Submit update workflow
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit Update', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ),
      );
    } else if (product.status == 'Live' || (isLiveSection && product.status.startsWith('Live'))) {
      return const SizedBox();
    } else if (product.status == 'Approved') {
       return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton(
            onPressed: () => onToggleVisibility(true), // Triggers publish and notification!
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Publish (Go Live)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ),
      );
    } else if (product.status == 'Unavailable' || product.status == 'Hidden') {
      return const SizedBox();
    }
    
    return const SizedBox();
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
