import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/user_model.dart';
import '../../../../features/store/domain/models/store_model.dart';
import '../../../../features/store/providers/subscription_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/notifications/providers/notification_provider.dart';
import '../../providers/dashboard_provider.dart';


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
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<DashboardProvider>().subscribeToStore(store.storeId);
            });

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
                          _buildTrialCountdownBanner(context),
                          if (store.isSuspended) _buildSuspensionBanner(context),
                          _buildGreetingHeader(context, store),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                _buildPayoutMetricsCard(context, store),
                                const SizedBox(height: 24),
                                _buildTodaysOverview(context, store),
                                const SizedBox(height: 28),
                                _buildNeedsAttention(context, store),
                                const SizedBox(height: 28),
                                _buildQuickActions(context),
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

  // 0. Trial Countdown Banner
  Widget _buildTrialCountdownBanner(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final sub = subProvider.currentSubscription;
        if (sub == null || !sub.isTrialActive || sub.status != 'trialing') return const SizedBox.shrink();

        final daysLeft = sub.trialEndsAt.difference(DateTime.now()).inDays;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFDE68A), // Light amber
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "$daysLeft Days left in Growth Trial",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // context.push('/subscription-plans');
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Upgrade Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuspensionBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Store Suspended by Platform Policy",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your store is temporarily offline and cannot accept new orders. You can still fulfill existing pending orders. Contact Admin Support for reinstatement.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB91C1C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, StoreModel store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50.withOpacity(0.4), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.background,
              backgroundImage: store.logo.isNotEmpty ? NetworkImage(store.logo) : null,
              child: store.logo.isEmpty ? const Icon(Icons.store, color: AppColors.grey500, size: 20) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  store.storeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    final unreadCount = notificationProvider.unreadCount;
                    return _buildHeaderIcon(
                      Icons.notifications_none_rounded,
                      showBadge: unreadCount > 0,
                      badgeCount: unreadCount > 9 ? "9+" : unreadCount.toString(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool showBadge = false, String badgeCount = ""}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badgeCount,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
              ),
            ),
          ),
      ],
    );
  }



  // 2.5 Payout Metrics Card
  Widget _buildPayoutMetricsCard(BuildContext context, StoreModel store) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
        .where('storeId', isEqualTo: store.storeId)
        .where('payoutStatus', isEqualTo: 'pending')
        .where('orderStatus', isEqualTo: 'Delivered')
        .snapshots(),
      builder: (context, snapshot) {
        double availableBalance = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final totalAmount = (data['totalAmount'] ?? 0.0) as num;
            final platformFee = (data['platformFee'] ?? 0.0) as num;
            availableBalance += (totalAmount - platformFee);
          }
        }

        // Get the next Monday for "Next Payout" date
        DateTime now = DateTime.now();
        int daysUntilMonday = 8 - now.weekday;
        if (daysUntilMonday == 8) daysUntilMonday = 1; // If today is Sunday, next Monday is tomorrow
        DateTime nextPayoutDate = now.add(Duration(days: daysUntilMonday));
        String formattedNextPayout = "${_getMonthAbbr(nextPayoutDate.month)} ${nextPayoutDate.day}, ${nextPayoutDate.year}";

        return GestureDetector(
          onTap: () => context.push('/analytics/earnings'),
          child: Container(
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF225732), Color(0xFF163E21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163E21).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A895C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Earnings & Payouts",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Track your earnings and manage payouts",
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Next Payout", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("₹${availableBalance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text("Expected on $formattedNextPayout", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Available Balance", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("₹${availableBalance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text("Ready to withdraw", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
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
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
                  childAspectRatio: 1.3,
                  children: [
                    _buildOverviewCard(context, "Orders Today", "$todayOrders", Colors.green, "▲ 20%", '/analytics/orders'),
                    _buildOverviewCard(context, "Revenue Today", "₹${todayRevenue.toStringAsFixed(0)}", Colors.orange, "▲ 18%", '/analytics/revenue'),
                    _buildOverviewCard(context, "Pending Orders", "$pendingCount", Colors.orange, "↓ 2", '/analytics/orders'),
                    _buildOverviewCard(context, "Products Live", "$productCount", Colors.purple, "▲ 5", '/analytics/products'),
                    _buildOverviewCard(context, "Followers", "${store.followers}", Colors.blue, "▲ 12%", '/analytics/followers', showChevron: true),
                    _buildOverviewCard(context, "Store Rating", store.rating.toStringAsFixed(1), Colors.orange, "▲ 0.2", '/analytics/rating', showChevron: true),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, Color color, String trend, String route, {bool showChevron = false}) {
    final isPositive = trend.contains('▲') || trend.contains('+') || trend == 'Excellent';
    final trendColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    String displayTrend = trend.replaceAll('▲ ', '').replaceAll('↓ ', '').replaceAll('+', '').replaceAll('-', '');
    final IconData trendIcon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.replaceAll(' Today', ''),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (title == "Products Live")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("6 Low", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("2 Out", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              )
            else 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(trendIcon, color: trendColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        displayTrend.contains('.') ? displayTrend : "$displayTrend%",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: trendColor),
                      ),
                    ],
                  ),
                  if (showChevron)
                    const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
                ],
              )
          ],
        ),
      ),
    );
  }

  // 4. Needs Attention
  Widget _buildNeedsAttention(BuildContext context, StoreModel store) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final pendingCount = dashboard.pendingOrdersCount;
        final lowStockCount = dashboard.lowStockCount;
        final outOfStockCount = dashboard.outOfStockCount;

        // If everything is clear, we might want to show a success state or hide it entirely
        final allClear = pendingCount == 0 && lowStockCount == 0 && outOfStockCount == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      allClear ? Icons.check_circle_outline : Icons.notifications_active_outlined, 
                      color: allClear ? Colors.green : AppColors.textPrimary, 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      allClear ? "All Caught Up!" : "Needs Attention",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (allClear)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green.shade400, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      "You're doing great!",
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green.shade800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "No pending orders or stock issues.",
                      style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    if (pendingCount > 0) ...[
                      _buildAttentionRow(
                        icon: Icons.assignment,
                        iconColor: Colors.orange.shade700,
                        title: "$pendingCount orders need processing",
                        subtitle: "Dispatch as soon as possible",
                        badgeText: "High Priority",
                        badgeColor: Colors.red.shade600,
                      ),
                    ],
                    if (pendingCount > 0 && (lowStockCount > 0 || outOfStockCount > 0))
                      Divider(height: 1, indent: 64, color: Colors.grey.shade100),
                    
                    if (lowStockCount > 0) ...[
                      _buildAttentionRow(
                        icon: Icons.inventory_2,
                        iconColor: Colors.orange.shade600,
                        title: "$lowStockCount products running low",
                        subtitle: "Restock to avoid missed sales",
                        badgeText: "Medium",
                        badgeColor: Colors.orange.shade600,
                      ),
                    ],
                    if (lowStockCount > 0 && outOfStockCount > 0)
                      Divider(height: 1, indent: 64, color: Colors.grey.shade100),

                    if (outOfStockCount > 0) ...[
                      _buildAttentionRow(
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.red.shade400,
                        title: "$outOfStockCount products out of stock",
                        subtitle: "Update availability to continue selling",
                        badgeText: "Low", // Matching image text visually
                        badgeColor: Colors.green.shade600, // Matching image color visually
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      }
    );
  }

  Widget _buildAttentionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
          ],
        ),
      ),
    );
  }

  // 5. Quick Actions
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                children: const [
                  Text("Edit", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionBtn(context, "Add Product", Icons.add_circle, Colors.green, () => context.push('/add-product')),
            _buildQuickActionBtn(context, "Orders", Icons.assignment, Colors.orange, () => context.push('/analytics/orders'), badge: 4),
            _buildQuickActionBtn(context, "Store Profile", Icons.store, Colors.green, () => context.push('/edit-store')),
            _buildQuickActionBtn(context, "Payouts", Icons.account_balance_wallet, Colors.blue, () => context.push('/analytics/earnings')),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionBtn(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {int? badge}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          badge.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
