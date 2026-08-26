import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';

class StoreActionsRow extends StatelessWidget {
  final String storeId;
  final String storeSlug;
  final String storeName;
  final VoidCallback onEditStore;
  final VoidCallback onPreviewStore;

  const StoreActionsRow({
    super.key,
    required this.storeId,
    required this.storeSlug,
    required this.storeName,
    required this.onEditStore,
    required this.onPreviewStore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Edit Store
          Expanded(
            child: _buildActionButton(
              label: 'Edit Store',
              icon: Icons.edit_outlined,
              isPrimary: false,
              onTap: onEditStore,
            ),
          ),
          const SizedBox(width: 10),
          // Share Store
          Expanded(
            child: _buildActionButton(
              label: 'Share',
              icon: Icons.share_outlined,
              isPrimary: false,
              onTap: () => _showShareBottomSheet(context),
            ),
          ),
          const SizedBox(width: 10),
          // Preview
          Expanded(
            child: _buildActionButton(
              label: 'Preview',
              icon: Icons.visibility_outlined,
              isPrimary: true,
              onTap: onPreviewStore,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.grey300,
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    final storeLink = 'https://freshga-homemades.web.app/store/$storeId';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ShareBottomSheet(
        storeName: storeName,
        storeSlug: storeSlug,
        storeLink: storeLink,
      ),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final String storeName;
  final String storeSlug;
  final String storeLink;

  const _ShareBottomSheet({
    required this.storeName,
    required this.storeSlug,
    required this.storeLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share Your Store',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Let customers discover $storeName',
            style: const TextStyle(fontSize: 13, color: AppColors.grey600),
          ),
          const SizedBox(height: 24),
          // Link card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    storeLink,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: storeLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share on',
            style: TextStyle(fontSize: 13, color: AppColors.grey600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSocialChip(context, 'WhatsApp', Icons.chat, const Color(0xFF25D366), storeLink),
              _buildSocialChip(context, 'Instagram', Icons.camera_alt, const Color(0xFFE1306C), storeLink),
              _buildSocialChip(context, 'More', Icons.share, AppColors.textSecondary, storeLink, isMore: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialChip(BuildContext context, String label, IconData icon, Color color, String url, {bool isMore = false}) {
    return GestureDetector(
      onTap: () {
        if (isMore || label == 'WhatsApp' || label == 'Instagram') {
          Share.share(
            'Check out $storeName on FreshGa!\n\n$url',
            subject: 'Check out this store!',
          );
        }
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
