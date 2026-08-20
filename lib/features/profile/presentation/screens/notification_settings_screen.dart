import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late Map<String, bool> _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preferences = {
      'new_orders': true,
      'payout_updates': true,
      'app_announcements': true,
      'whatsapp_alerts': false,
    };
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('notificationPreferences')) {
          _preferences = Map<String, bool>.from(data['notificationPreferences']);
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggle(String key, bool val) async {
    if (user == null) return;
    
    setState(() {
      _preferences[key] = val;
    });
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'notificationPreferences': _preferences,
      });
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _preferences[key] = !val;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose what notifications you want to receive from FreshGa Admin and Customers.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildSectionCard([
              _buildSwitchTile(
                title: 'New Order Alerts',
                subtitle: 'Get live alerts when a customer places an order for your homestyle products.',
                icon: Icons.delivery_dining_rounded,
                value: _preferences['new_orders'] ?? true,
                onChanged: (val) => _toggle('new_orders', val),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _buildSwitchTile(
                title: 'Payout Updates',
                subtitle: 'Get notified when your earnings are processed and settled.',
                icon: Icons.account_balance_wallet_rounded,
                value: _preferences['payout_updates'] ?? true,
                onChanged: (val) => _toggle('payout_updates', val),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _buildSwitchTile(
                title: 'App Announcements',
                subtitle: 'Updates from FreshGa admin regarding compliance and new features.',
                icon: Icons.campaign_rounded,
                value: _preferences['app_announcements'] ?? true,
                onChanged: (val) => _toggle('app_announcements', val),
              ),
            ]),

            const SizedBox(height: 24),
            const Text(
              'Messaging Channels',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            _buildSectionCard([
              _buildSwitchTile(
                title: 'WhatsApp Alerts',
                subtitle: 'Receive instant order notifications on your registered WhatsApp number.',
                icon: Icons.chat_bubble_rounded,
                value: _preferences['whatsapp_alerts'] ?? false,
                onChanged: (val) => _toggle('whatsapp_alerts', val),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
      ),
    );
  }
}
