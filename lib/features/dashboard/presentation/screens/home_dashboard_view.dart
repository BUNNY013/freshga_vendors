import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not authenticated"));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        final userModel = UserModel.fromJson(userSnap.data!.data() as Map<String, dynamic>);
        final storeId = userModel.storeId;

        if (storeId.isEmpty) {
          return const Center(child: Text("Store not set up."));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').doc(storeId).snapshots(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData || !storeSnap.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final store = StoreModel.fromJson(storeSnap.data!.data() as Map<String, dynamic>);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingHeader(store),
                    const SizedBox(height: 32),
                    _buildQuickStats(context, store),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildMotivationalInsights(),
                    const SizedBox(height: 32),
                    _buildEmptyState(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGreetingHeader(StoreModel store) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Good Morning 👋", style: AppTextStyles.subtitle),
              const SizedBox(height: 4),
              Text(store.storeName, style: AppTextStyles.h1),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grey200,
            border: Border.all(color: AppColors.primary, width: 2),
            image: store.logo.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(store.logo),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: store.logo.isEmpty
              ? const Center(child: Icon(Icons.store, color: AppColors.primary))
              : null,
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, StoreModel store) {
    // For products count, we can do a stream or just show 0 if not cached in store.
    // To keep it clean, we'll use a StreamBuilder just for the products count.
    return StreamBuilder<AggregateQuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('storeId', isEqualTo: store.storeId)
          .count()
          .get()
          .asStream(),
      builder: (context, prodSnap) {
        final productCount = prodSnap.data?.count ?? 0;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard("Products", productCount.toString(), Icons.inventory_2),
            _buildStatCard("Orders", store.totalOrders.toString(), Icons.receipt_long),
            _buildStatCard("Followers", store.followers.toString(), Icons.favorite),
            _buildStatCard("Store Views", "0", Icons.remove_red_eye),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton("Add Product", Icons.add_circle_outline, () {
          context.push('/add-product');
        }),
        _buildActionButton("View Orders", Icons.receipt_long, () {}),
        _buildActionButton("Edit Store", Icons.edit_outlined, () {
          context.push('/edit-store');
        }),
        _buildActionButton("Share", Icons.share_outlined, () {}),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Insights 🚀",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text("🔥", style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Your store setup is complete. Add your first product!",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // This empty state replaces boring tables when there's no data.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            "Your food journey starts here 🚀",
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your first homemade product and start building your brand.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.push('/add-product');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Add First Product",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
