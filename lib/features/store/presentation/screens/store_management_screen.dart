import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StoreManagementScreen extends StatelessWidget {
  const StoreManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not authenticated"));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<DocumentSnapshot>(
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
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Store data not found."));
              }

              final store = StoreModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStoreHeader(store),
                    const SizedBox(height: 24),
                    _buildStatsRow(store),
                    const SizedBox(height: 24),
                    _buildActions(context, store),
                    const SizedBox(height: 32),
                    const Divider(),
                    _buildProfileSettings(context),
                  ],
                ),
              );
            },
          );
        },
      ),
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
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                image: store.banner.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(store.banner),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: store.banner.isEmpty
                  ? const Center(child: Icon(Icons.store, size: 64, color: AppColors.grey400))
                  : null,
            ),
            Positioned(
              bottom: -50,
              child: Container(
                width: 100,
                height: 100,
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
            ),
          ],
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(store.storeName, style: AppTextStyles.h2),
            if (store.verified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.green, size: 20),
            ]
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            store.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(StoreModel store) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("Followers", store.followers.toString()),
        _buildStatItem("Likes", store.likesCount.toString()),
        _buildStatItem("Products", store.productsCount.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
      ],
    );
  }

  Widget _buildActions(BuildContext context, StoreModel store) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            context.push('/edit-store');
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text("Edit Store"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.grey300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Share Store
          },
          icon: const Icon(Icons.share, size: 18),
          label: const Text("Share"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSettings(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.account_balance, color: AppColors.grey600),
          title: const Text("Bank & Payouts"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none, color: AppColors.grey600),
          title: const Text("Notification Settings"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.help_outline, color: AppColors.grey600),
          title: const Text("Help & Support"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }
}
