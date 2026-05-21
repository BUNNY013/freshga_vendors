import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart' as vendor_auth;
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: user == null
          ? const Center(child: Text("Not authenticated"))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                final userData = userSnap.data!.data() as Map<String, dynamic>?;
                if (userData == null) return const Center(child: Text("User data not found"));
                
                final userModel = UserModel.fromJson(userData);
                final storeId = userModel.storeId;
                
                return FutureBuilder<DocumentSnapshot>(
                  future: storeId.isNotEmpty 
                      ? FirebaseFirestore.instance.collection('stores').doc(storeId).get()
                      : Future.value(null),
                  builder: (context, storeSnap) {
                    StoreModel? store;
                    if (storeSnap.hasData && storeSnap.data != null && storeSnap.data!.exists) {
                      store = StoreModel.fromJson(storeSnap.data!.data() as Map<String, dynamic>);
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildProfileHeader(userModel, store),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Business Settings"),
                          _buildBusinessSettingsList(context),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Support"),
                          _buildSupportList(context),
                          const SizedBox(height: 24),
                          _buildAccountActions(context),
                          const SizedBox(height: 48),
                        ],
                      ),
                    );
                  }
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(UserModel userModel, StoreModel? store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey200,
              image: store != null && store.logo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(store.logo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: store == null || store.logo.isEmpty
                ? const Icon(Icons.storefront, size: 30, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        store?.storeName ?? 'FreshGa Vendor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (store?.verified ?? false) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (userModel.phone.isNotEmpty)
                  Text(
                    userModel.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.grey500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBusinessSettingsList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(Icons.storefront_outlined, "Edit Store Info", () => context.push('/edit-store')),
          _buildDivider(),
          _buildListTile(Icons.account_balance_wallet_outlined, "Bank & Payouts", () {}),
          _buildDivider(),
          _buildListTile(Icons.notifications_outlined, "Notification Settings", () {}),
          _buildDivider(),
          _buildListTile(Icons.local_shipping_outlined, "Delivery Settings", () {}),
        ],
      ),
    );
  }

  Widget _buildSupportList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(Icons.help_outline_rounded, "Help & Support", () {}),
          _buildDivider(),
          _buildListTile(Icons.policy_outlined, "Terms & Policies", () {}),
          _buildDivider(),
          _buildListTile(Icons.privacy_tip_outlined, "Privacy Policy", () {}),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () {
              context.read<vendor_auth.AuthProvider>().signOut();
              context.go('/login');
            },
          ),
          _buildDivider(),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
            title: const Text(
              "Delete Account",
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () {
              // Delete Account Logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, color: AppColors.grey200);
  }
}
