import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../features/store/domain/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';


class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showNavSnackbar(BuildContext context, String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $destination...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not authenticated"));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        if (!userSnap.data!.exists) return const Center(child: Text("User data not found."));

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Center(child: Text("Invalid user data."));

        final userModel = UserModel.fromJson(userData);
        final storeId = userModel.storeId;

        if (storeId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/store-setup');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').doc(storeId).snapshots(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData || !storeSnap.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final store = StoreModel.fromJson(storeSnap.data!.data() as Map<String, dynamic>);

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreetingHeader(context, store),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStoreStatusCard(context, store),
                                const SizedBox(height: 24),
                                _buildPayoutMetricsCard(context),
                                const SizedBox(height: 24),
                                _buildTodaysOverview(context, store),
                                const SizedBox(height: 28),
                                _buildPendingActions(context, store),
                                const SizedBox(height: 28),
                                _buildRecentOrders(context, store),
                                const SizedBox(height: 28),
                                _buildQuickActions(context),
                                const SizedBox(height: 28),
                                _buildBusinessTip(),
                                const SizedBox(height: 40),
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
          },
        );
      },
    );
  }

  // 1. Greeting Header
  Widget _buildGreetingHeader(BuildContext context, StoreModel store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_greeting()} 👋",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    store.storeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (store.verified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                  ],
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.grey200,
                backgroundImage: store.logo.isNotEmpty ? NetworkImage(store.logo) : null,
                child: store.logo.isEmpty ? const Icon(Icons.store, color: AppColors.grey500) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Store Status Card
  Widget _buildStoreStatusCard(BuildContext context, StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: store.isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    store.isActive ? "Store is Open" : "Store is Paused",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: store.isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              Switch(
                value: store.isActive,
                activeColor: Colors.green,
                onChanged: (val) {
                  FirebaseFirestore.instance.collection('stores').doc(store.storeId).update({'isActive': val});
                },
              ),
            ],
          ),
          if (store.isActive) ...[
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Accepting Orders", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text("Yes", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 30, color: AppColors.grey200),
                Column(
                  children: [
                    const Text("Next Pickup", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text("3:00 PM", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  // 2.5 Payout Metrics Card
  Widget _buildPayoutMetricsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/analytics/earnings'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.account_balance_wallet_rounded, color: Colors.green.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Earnings & Payouts",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: AppColors.grey500),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.background),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Next Payout", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text("₹12,450", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Expected Jun 15", style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
                Container(width: 1, height: 40, color: AppColors.grey200),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Available Balance", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text("₹5,200", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Ready to withdraw", style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. Today's Overview
  Widget _buildTodaysOverview(BuildContext context, StoreModel store) {
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () => _showNavSnackbar(context, 'All Analytics'),
              child: const Text("View All", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            )
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: store.storeId).where('createdAt', isGreaterThanOrEqualTo: todayStart).snapshots(),
          builder: (context, todaySnap) {
            final todayDocs = todaySnap.data?.docs ?? [];
            final todayOrders = todayDocs.length;
            double todayRevenue = 0;
            int pendingCount = 0;

            for (final doc in todayDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final status = (d['orderStatus'] ?? '').toString().toLowerCase();
              final amount = (d['totalAmount'] ?? 0.0) as num;
              todayRevenue += amount;
              if (status == 'new' || status == 'accepted' || status == 'packed') pendingCount++;
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: store.storeId).snapshots(),
              builder: (context, prodSnap) {
                final productCount = prodSnap.data?.docs.length ?? 0;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildOverviewCard(context, "Orders Today", "$todayOrders", Icons.shopping_bag_outlined, Colors.blue, "▲ 20%", '/analytics/orders'),
                    _buildOverviewCard(context, "Revenue Today", "₹${todayRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined, Colors.orange, "▲ 18%", '/analytics/revenue'),
                    _buildOverviewCard(context, "Pending Orders", "$pendingCount", Icons.pending_actions, Colors.red, "↓ 2", '/analytics/orders'),
                    _buildOverviewCard(context, "Products Live", "$productCount", Icons.inventory_2_outlined, Colors.purple, "▲ 5", '/analytics/products'),
                    _buildOverviewCard(context, "Followers", "${store.followers}", Icons.favorite_border, Colors.pink, "▲ 12%", '/analytics/followers'),
                    _buildOverviewCard(context, "Store Rating", store.rating.toStringAsFixed(1), Icons.star_outline, Colors.amber, "▲ 0.2", '/analytics/rating'),
                    // Mocked Data
                    _buildOverviewCard(context, "Store Views", "3,420", Icons.visibility_outlined, Colors.teal, "▲ 15%", '/analytics/views'),
                    _buildOverviewCard(context, "Seller Health", "96%", Icons.health_and_safety_outlined, Colors.green, "Excellent", '/analytics/health'),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, IconData icon, Color color, String trend, String route) {
    final isPositive = trend.contains('▲') || trend.contains('+') || trend == 'Excellent';
    final trendColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    String displayTrend = trend.replaceAll('▲ ', '').replaceAll('↓ ', '').replaceAll('+', '').replaceAll('-', '');

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.replaceAll(' Today', ''),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1.0),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: trendColor,
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        displayTrend,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: trendColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Pending Actions
  Widget _buildPendingActions(BuildContext context, StoreModel store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pending Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("4 orders need your attention", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    Text("Tap to view and process", style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.orange.shade700),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Recent Orders
  Widget _buildRecentOrders(BuildContext context, StoreModel store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Orders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("View All", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            )
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: store.storeId).orderBy('createdAt', descending: true).limit(3).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text("No recent orders.");

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final orderId = docs[index].id.substring(0, 6).toUpperCase();
                  final amount = data['totalAmount'] ?? 0.0;
                  final status = (data['orderStatus'] ?? 'Unknown').toString().toUpperCase();
                  final createdAtStr = data['createdAt'] as String?;
                  final timeText = createdAtStr != null ? _timeAgo(DateTime.parse(createdAtStr)) : '';

                  Color statusColor = Colors.grey;
                  if (status == 'PREPARING' || status == 'ACCEPTED') statusColor = Colors.orange;
                  if (status == 'PACKED') statusColor = Colors.blue;
                  if (status == 'DELIVERED') statusColor = Colors.green;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                    ),
                    title: Text("#$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(timeText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₹${(amount as num).toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // 6. Quick Actions
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildActionButton(context, "Add Product", Icons.add_circle_outline, Colors.blue, () => context.push('/add-product'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, "Manage", Icons.inventory_2_outlined, Colors.purple, () => context.push('/products'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildActionButton(context, "Store Settings", Icons.storefront, Colors.orange, () => context.push('/edit-store'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, "Analytics", Icons.bar_chart, Colors.teal, () => _showNavSnackbar(context, "All Analytics"))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  // 7. Business Tip
  Widget _buildBusinessTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Business Tip", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                SizedBox(height: 4),
                Text("Stores with complete profiles receive 40% more customer visits.", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
