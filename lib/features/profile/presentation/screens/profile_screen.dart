import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart' as vendor_auth;
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPremiumHeader(context, userModel, store),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Business Settings"),
                          _buildBusinessSettingsList(context),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Support"),
                          _buildSupportList(context),
                          _buildSectionTitle("Account"),
                          _buildAccountActions(context),
                          const SizedBox(height: 32),
                          const Center(
                            child: Text(
                              'Version 1.0.0',
                              style: TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                );
              },
            ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, UserModel userModel, StoreModel? store) {
    final logoUrl = store?.logo ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: ClipOval(
                      child: logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, size: 32, color: AppColors.primary),
                            )
                          : const Icon(Icons.storefront_rounded, size: 32, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store?.storeName ?? 'FreshGa Vendor',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (userModel.phone.isNotEmpty)
                          Text(
                            userModel.phone,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(Icons.star_rounded, "Customer Feedback", () => context.push('/profile/feedback')),
          _buildDivider(),
          _buildListTile(Icons.account_balance_wallet_rounded, "Bank Details", () => context.push('/profile/payouts')),
          _buildDivider(),
          _buildListTile(Icons.storefront_rounded, "Business Details", () => context.push('/store/business-details')),
          _buildDivider(),
          _buildListTile(Icons.card_membership_rounded, "Subscriptions & Billing", () => context.push('/subscription')),
          _buildDivider(),
          _buildListTile(Icons.local_shipping_rounded, "Delivery Settings", () => context.push('/store/order-fulfillment')),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(Icons.help_outline_rounded, "Help & Support", () => context.push('/profile/support')),
          _buildDivider(),
          _buildListTile(Icons.policy_rounded, "Terms & Policies", () {}),
          _buildDivider(),
          _buildListTile(Icons.privacy_tip_rounded, "Privacy Policy", () {}),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.textPrimary),
            title: const Text(
              "Accounts",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () => context.push('/profile/accounts'),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.grey200),
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
            onTap: () async {
              await context.read<vendor_auth.AuthProvider>().signOut();
              if (context.mounted) {
                context.go('/login');
              }
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
