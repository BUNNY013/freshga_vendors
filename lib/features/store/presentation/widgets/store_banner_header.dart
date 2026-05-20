import 'package:flutter/material.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';

class StoreBannerHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBannerWithLogo(),
        const SizedBox(height: 60),
        _buildIdentity(),
      ],
    );
  }

  Widget _buildBannerWithLogo() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Banner
        GestureDetector(
          onTap: onEditBanner,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey200,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Banner image or gradient placeholder
                store.banner.isNotEmpty
                    ? Image.network(
                        store.banner,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
                      )
                    : _buildBannerPlaceholder(),
                // Gradient overlay for depth
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
                // Edit banner overlay
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
        ),
        // Logo overlapping the banner
        Positioned(
          bottom: -50,
          child: GestureDetector(
            onTap: onEditLogo,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: store.logo.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(store.logo),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: store.logo.isEmpty
                      ? const Icon(Icons.fastfood, size: 42, color: AppColors.grey400)
                      : null,
                ),
                // Edit logo button
                if (onEditLogo != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildIdentity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Store name + verified
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  store.storeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (store.verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // @handle
          Text(
            '@${store.storeSlug}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Bio
          if (store.description.isNotEmpty)
            Text(
              store.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          // Dispatch time badge
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  'Ships in ${store.dispatchTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
