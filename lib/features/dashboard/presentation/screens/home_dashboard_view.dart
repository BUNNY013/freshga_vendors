import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreHeader(store),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 32),
                        const Text("Dashboard", style: AppTextStyles.h2),
                        const SizedBox(height: 16),
                        _buildQuickStats(context, store),
                        const SizedBox(height: 32),
                        const Text("Recent Activity", style: AppTextStyles.h2),
                        const SizedBox(height: 16),
                        _buildRecentActivity(context, store.storeId),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoreHeader(StoreModel store) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                image: store.banner.isNotEmpty
                    ? DecorationImage(image: NetworkImage(store.banner), fit: BoxFit.cover)
                    : null,
              ),
              child: store.banner.isEmpty
                  ? const Center(child: Icon(Icons.store, size: 64, color: AppColors.grey400))
                  : null,
            ),
            Positioned(
              bottom: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  image: store.logo.isNotEmpty
                      ? DecorationImage(image: NetworkImage(store.logo), fit: BoxFit.cover)
                      : null,
                ),
                child: store.logo.isEmpty
                    ? const Icon(Icons.fastfood, size: 40, color: AppColors.grey400)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(store.storeName, style: AppTextStyles.h2),
            if (store.verified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            ]
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 14, color: AppColors.grey600),
            const SizedBox(width: 4),
            Text("${store.followers} Followers", style: const TextStyle(color: AppColors.grey600, fontSize: 13)),
            const SizedBox(width: 16),
            const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.grey600),
            const SizedBox(width: 4),
            Text("${store.likesCount} Likes", style: const TextStyle(color: AppColors.grey600, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, StoreModel store) {
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
            _buildStatCard("Products", productCount.toString(), Icons.inventory_2_outlined),
            _buildStatCard("Orders", store.totalOrders.toString(), Icons.receipt_long_outlined),
            _buildStatCard("Followers", store.followers.toString(), Icons.people_outline),
            _buildStatCard("Likes", store.likesCount.toString(), Icons.favorite_outline),
            _buildStatCard("Revenue", "₹0", Icons.account_balance_wallet_outlined),
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
        border: Border.all(color: AppColors.grey200),
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
                  style: const TextStyle(fontSize: 12, color: AppColors.grey600),
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
        _buildActionButton("Edit Store", Icons.edit_outlined, () {
          context.push('/edit-store');
        }),
        _buildActionButton("Share Store", Icons.share_outlined, () {}),
        _buildActionButton("View Orders", Icons.receipt_long_outlined, () {
          // DashboardScreen controls tabs, but for now we'll do nothing or push a route if it was available.
        }),
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
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, String storeId) {
    // Shows latest orders or fallback empty state
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your journey begins! 🚀", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("When customers place orders, they will appear here.", style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.grey200,
                child: Icon(Icons.receipt, color: AppColors.primary, size: 20),
              ),
              title: Text("New Order - ₹${data['totalAmount'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("From ${data['customerName'] ?? 'Customer'}", style: const TextStyle(fontSize: 12)),
              trailing: Text(
                data['orderStatus'] ?? 'New',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
