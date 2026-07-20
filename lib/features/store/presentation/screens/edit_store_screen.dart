import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class EditStoreScreen extends StatelessWidget {
  const EditStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Edit Store',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMenuItem(
              context,
              icon: Icons.image_outlined,
              title: 'Store Appearance',
              subtitle: 'Banner, Logo & Brand Colors',
              route: '/store/appearance',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: 'Store Information',
              subtitle: 'Store name, tagline & description',
              route: '/store/info',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.business_outlined, // using business icon
              title: 'Business Details',
              subtitle: 'Business info, address & documents',
              route: '/store/business-details',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Shipping Settings',
              subtitle: 'Delivery areas & fulfillment rules',
              route: '/store/order-fulfillment',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.label_outline, // using tag/label icon
              title: 'Marketplace Categories',
              subtitle: 'Select categories for your store',
              route: '/store/categories',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.article_outlined, // using document icon
              title: 'Policies',
              subtitle: 'Shipping, Refund & Cancellation',
              route: '/store/policies',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'FAQ',
              subtitle: 'Frequently asked questions',
              route: '/store/faq',
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 64),
            _buildMenuItem(
              context,
              icon: Icons.link_outlined,
              title: 'Social Links',
              subtitle: 'Instagram, Facebook & Website',
              route: '/store/social-links',
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

}
