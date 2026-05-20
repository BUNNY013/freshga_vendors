import 'package:flutter/material.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';

class StoreStatChips extends StatelessWidget {
  final StoreModel store;
  final int productCount;

  const StoreStatChips({
    super.key,
    required this.store,
    required this.productCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF5B8DEF),
            value: _formatCount(store.followers),
            label: 'Followers',
          ),
          _buildDivider(),
          _buildStat(
            icon: Icons.favorite,
            iconColor: const Color(0xFFEF5B8D),
            value: _formatCount(store.likesCount),
            label: 'Likes',
          ),
          _buildDivider(),
          _buildStat(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            value: _formatCount(productCount),
            label: 'Products',
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.grey200,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
