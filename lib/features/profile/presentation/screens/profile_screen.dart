import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Profile', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildSettingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grey200,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Center(child: Icon(Icons.store, size: 40, color: AppColors.primary)),
        ),
        const SizedBox(height: 16),
        const Text("FreshGa HomeMades", style: AppTextStyles.h2),
        const SizedBox(height: 4),
        const Text("vendor@freshga.com", style: TextStyle(color: AppColors.grey600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text("Verified Kitchen", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildListTile(Icons.store, "Edit Store Info", () {}),
          _buildListTile(Icons.account_balance, "Bank & Payouts", () {}),
          _buildListTile(Icons.notifications_none, "Notification Settings", () {}),
          _buildListTile(Icons.help_outline, "Help & Support", () {}),
          _buildListTile(Icons.policy_outlined, "Terms & Policies", () {}),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              context.read<AuthProvider>().signOut();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.grey600),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 56),
      ],
    );
  }
}
