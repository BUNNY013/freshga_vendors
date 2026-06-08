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

  // --- Helpers ---

  double get _startingPrice {
    if (product.variants.isEmpty) return 0;
    return product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  double get _maxPrice {
    if (product.variants.isEmpty) return 0;
    return product.variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  int get _totalStock => product.variants.fold(0, (sum, v) => sum + v.stock);

  bool get _isOutOfStock => product.variants.isNotEmpty && _totalStock == 0;

  bool get _isLowStock => _totalStock > 0 && _totalStock <= 5;

  String get _statusLabel {
    if (!product.isActive) return 'Hidden';
    if (_isOutOfStock) return 'Out of Stock';
    return 'Live';
  }

  Color get _statusColor {
    if (!product.isActive) return AppColors.grey500;
    if (_isOutOfStock) return AppColors.error;
    return const Color(0xFF4CAF50);
  }

  String get _priceLabel {
    if (product.variants.isEmpty) return 'Price TBA';
    if (_startingPrice == _maxPrice) return '₹${_startingPrice.toStringAsFixed(0)}';
    return '₹${_startingPrice.toStringAsFixed(0)} – ₹${_maxPrice.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return isListView ? _buildListCard(context) : _buildGridCard(context);
  }

  // ==========================================
  // GRID VIEW CARD
  // ==========================================
  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1 — Product Image with Overlays
            _buildImageSection(),

            // SECTIONS 2-6 — Info, Variants, Engagement, Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SECTION 2 — Status Chips
                  _buildStatusChips(),

                  const SizedBox(height: 6),

                  // SECTION 3 — Product Info
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.shortDescription,
                      style: const TextStyle(fontSize: 11, color: AppColors.grey500, height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.variants.length > 1 ? 'Starting $_priceLabel' : _priceLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SECTION 4 — Variant Preview Chips
                  if (product.variants.isNotEmpty) _buildVariantChips(),

                  const SizedBox(height: 8),

                  // SECTION 5 — Engagement Row
                  _buildEngagementRow(),

                  const SizedBox(height: 8),

                  // SECTION 6 — Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LIST VIEW CARD
  // ==========================================
  Widget _buildListCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                    // Status dot
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.variants.length > 1 ? 'Starting $_priceLabel' : _priceLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMiniStat(Icons.style_outlined, '${product.variants.length}'),
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.favorite_rounded, '${product.likes}', color: const Color(0xFFE57373)),
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.shopping_bag_rounded, '${product.totalOrders}', color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Column(
              children: [
                _buildMiniActionBtn(Icons.edit_outlined, onEdit),
                const SizedBox(height: 4),
                _buildMiniActionBtn(Icons.remove_red_eye_outlined, onPreview),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SHARED SUB-WIDGETS
  // ==========================================

  /// Section 1 — Image with overlays
  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          // Gradient overlay at bottom for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.15)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
              ),
            ),
          ),
          // Top-right: Status chip
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom-right: Variants count badge
          if (product.variants.length > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${product.variants.length} variants',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Section 2 — Status Chips
  Widget _buildStatusChips() {
    final List<_ChipData> chips = [];

    if (product.isTrending) chips.add(_ChipData('🔥 Trending', const Color(0xFFFFF3E0), const Color(0xFFE65100)));
    if (product.isFeatured) chips.add(_ChipData('⭐ Best Seller', const Color(0xFFFCE4EC), const Color(0xFFC62828)));
    if (_isLowStock) chips.add(_ChipData('Low Stock', const Color(0xFFFFF8E1), const Color(0xFFF57F17)));
    if (_isOutOfStock) chips.add(_ChipData('Out of Stock', const Color(0xFFFFEBEE), const Color(0xFFC62828)));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: chips.map((chip) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chip.bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            chip.label,
            style: TextStyle(
              color: chip.textColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        )).toList(),
      ),
    );
  }

  /// Section 4 — Variant Preview Chips
  Widget _buildVariantChips() {
    final maxShow = 3;
    final visibleVariants = product.variants.take(maxShow).toList();
    final remaining = product.variants.length - maxShow;

    return SizedBox(
      height: 26,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...visibleVariants.map((v) => Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: v.isAvailable
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.grey200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: v.isAvailable
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.grey300,
                width: 1,
              ),
            ),
            child: Text(
              '${v.label.isEmpty ? "Variant" : v.label}  ₹${v.discountPrice > 0 ? v.discountPrice.toStringAsFixed(0) : v.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: v.isAvailable ? AppColors.primary : AppColors.grey500,
              ),
            ),
          )),
          if (remaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$remaining more',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Section 5 — Engagement Row
  Widget _buildEngagementRow() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          _buildMiniStat(Icons.favorite_rounded, '${product.likes}', color: const Color(0xFFE57373)),
          const SizedBox(width: 12),
          _buildMiniStat(Icons.shopping_bag_rounded, '${product.totalOrders}', color: AppColors.primary),
          const SizedBox(width: 12),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 6 — Action Buttons
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.grey200.withOpacity(0.8))),
      ),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: onEdit,
              color: AppColors.textPrimary,
            ),
          ),
          Container(width: 1, height: 18, color: AppColors.grey200),
          Expanded(
            child: _buildActionBtn(
              icon: product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              label: product.isActive ? 'Hide' : 'Make Live',
              onTap: () => onToggleVisibility(!product.isActive),
              color: product.isActive ? AppColors.grey600 : const Color(0xFF4CAF50),
            ),
          ),
          Container(width: 1, height: 18, color: AppColors.grey200),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.remove_red_eye_outlined,
              label: 'Preview',
              onTap: onPreview,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MICRO WIDGETS
  // ==========================================

  Widget _buildMiniStat(IconData icon, String value, {Color color = AppColors.grey600}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.grey600),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: Center(
        child: Icon(Icons.fastfood_outlined, color: AppColors.grey400, size: 36),
      ),
    );
  }
}

/// Internal chip data helper
class _ChipData {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _ChipData(this.label, this.bgColor, this.textColor);
}
