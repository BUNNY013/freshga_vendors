import 'package:flutter/material.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';

class StoreBannerHeader extends StatefulWidget {
  final StoreModel store;
  final VoidCallback? onEditBanner;
  final VoidCallback? onEditLogo;

  const StoreBannerHeader({
    super.key,
    required this.store,
    this.onEditBanner,
    this.onEditLogo,
  });

  @override
  State<StoreBannerHeader> createState() => _StoreBannerHeaderState();
}

class _StoreBannerHeaderState extends State<StoreBannerHeader> {
  bool _isDescExpanded = false;

  StoreModel get store => widget.store;
  VoidCallback? get onEditBanner => widget.onEditBanner;
  VoidCallback? get onEditLogo => widget.onEditLogo;

  @override
  Widget build(BuildContext context) {
    // Banner 160px + 56px for the logo overflow below banner
    const double bannerHeight = 160;
    const double logoSize = 96;
    const double logoOverlap = 40; // how much the logo overlaps the banner
    const double totalHeaderHeight = bannerHeight + (logoSize - logoOverlap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner + profile row with proper overlap via Stack
        SizedBox(
          height: totalHeaderHeight,
          child: Stack(
            children: [
              // Banner at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: bannerHeight,
                child: _buildBanner(),
              ),
              // Profile row at bottom, overlapping banner
              Positioned(
                bottom: 0,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ─── Big attractive logo ─────────────────────
                    _buildLogo(),
                    const SizedBox(width: 16),
                    // ─── Store name + handle ─────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    store.storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.4,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (store.verified) ...[
                                  const SizedBox(width: 5),
                                  const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 19),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '@${store.storeSlug}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey500.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Description
        if (store.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: _buildExpandableDescription(),
          ),
      ],
    );
  }

  // ─── Banner ───────────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    return GestureDetector(
      onTap: onEditBanner,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey200,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            store.banner.isNotEmpty
                ? Image.network(
                    store.banner,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
                  )
                : _buildBannerPlaceholder(),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            // Edit banner pill
            if (onEditBanner != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Edit Banner',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            // Featured badge
            if (store.isFeatured)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.black, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Logo ─────────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return GestureDetector(
      onTap: onEditLogo,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 4),
                image: store.logo.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(store.logo),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: store.logo.isEmpty
                  ? const Icon(Icons.fastfood, size: 40, color: AppColors.grey400)
                  : null,
            ),
            // Edit logo button
            if (onEditLogo != null)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Banner Placeholder ───────────────────────────────────────────────────────

  Widget _buildBannerPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD66853),
            Color(0xFFE8896B),
            Color(0xFFD4956A),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.white54),
      ),
    );
  }

  // ─── Expandable Description ───────────────────────────────────────────────────

  Widget _buildExpandableDescription() {
    const int maxChars = 100;
    final desc = store.description;
    final isLong = desc.length > maxChars;
    final displayText = (!_isDescExpanded && isLong)
        ? '${desc.substring(0, maxChars).trimRight()}...'
        : desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isDescExpanded ? 'See less' : 'See more',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
