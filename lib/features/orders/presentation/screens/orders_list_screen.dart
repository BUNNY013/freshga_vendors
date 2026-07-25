import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/order_model.dart';
import '../widgets/order_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import 'vendor_issues_screen.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const Scaffold(body: Center(child: Text('User data error')));
        }

        final storeId = UserModel.fromJson(userData).storeId;

        if (storeId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Store not set up')));
        }

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Orders',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorIssuesScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: const TabBar(
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.3),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'New'),
                  Tab(text: 'Preparing'),
                  Tab(text: 'Ready'),
                  Tab(text: 'Shipped'),
                  Tab(text: 'Delivered'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OrderListTab(storeId: storeId, statusFilter: const ['New']),
                _OrderListTab(storeId: storeId, statusFilter: const ['Accepted']),
                _OrderListTab(storeId: storeId, statusFilter: const ['Packed']),
                _OrderListTab(storeId: storeId, statusFilter: const ['Shipped']),
                _OrderListTab(storeId: storeId, statusFilter: const ['Delivered']),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderListTab extends StatelessWidget {
  final String storeId;
  final List<String> statusFilter;

  const _OrderListTab({required this.storeId, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    // Fetch ALL orders for this store (only storeId filter = no composite index needed)
    // then filter by status client-side. This avoids needing whereIn + orderBy indexes.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load orders.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) return _buildEmptyState();

        // Client-side filter by status (case-insensitive)
        final orders = snapshot.data!.docs
            .map((doc) =>
                OrderModel.fromJson(doc.data() as Map<String, dynamic>))
            .where((order) => statusFilter.any(
                (s) => s.toLowerCase() == order.orderStatus.toLowerCase()))
            .toList();

        if (orders.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return OrderCard(
              order: orders[index],
              onStatusUpdate: (newStatus, payload) {
                final order = orders[index];
                final timeline = List<Map<String, dynamic>>.from(order.timeline);

                String? note;
                if (payload != null && payload.containsKey('shippingMethod')) {
                  final method = payload['shippingMethod'];
                  if (method == 'Courier') note = 'Shipped via ${payload['shippingProvider']} (Tracking: ${payload['trackingId']})';
                  if (method == 'Hyperlocal') note = 'Dispatched via ${payload['shippingProvider']}';
                  if (method == 'Local Transport') note = 'Sent via ${payload['shippingProvider']} (LR: ${payload['receiptNumber']})';
                  if (method == 'Self Delivery') note = 'Vendor delivering directly by ${payload['deliveryTime']}';
                } else if (payload != null && payload.containsKey('rejectionReason')) {
                  note = 'Reason: ${payload['rejectionReason']}';
                }

                timeline.add({
                  'status': newStatus,
                  'time': DateTime.now().toIso8601String(),
                  if (note != null) 'note': note,
                });

                final updates = <String, dynamic>{
                  'orderStatus': newStatus,
                  'timeline': timeline,
                  'updatedAt': DateTime.now().toIso8601String(),
                };
                if (payload != null) {
                  if (payload.containsKey('shippingMethod')) updates['shippingDetails'] = payload;
                  if (payload.containsKey('rejectionReason')) updates['rejectionReason'] = payload['rejectionReason'];
                }

                FirebaseFirestore.instance
                    .collection('orders')
                    .doc(order.orderId)
                    .update(updates);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String emoji;
    String message;
    switch (statusFilter.first.toLowerCase()) {
      case 'new':
      case 'accepted':
        emoji = '📬';
        message = 'No new orders yet.\nShare your store to get your first order!';
        break;
      case 'packed':
        emoji = '📦';
        message = 'No orders being prepared right now.';
        break;
      case 'shipped':
        emoji = '🚚';
        message = 'No orders out for delivery.';
        break;
      case 'delivered':
        emoji = '✅';
        message = 'No delivered orders yet.';
        break;
      default:
        emoji = '🗂️';
        message = 'No orders here.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
