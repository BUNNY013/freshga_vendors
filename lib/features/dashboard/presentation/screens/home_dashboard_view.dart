import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../features/store/domain/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not authenticated"));

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnap.data!.exists) {
          return const Center(child: Text("User data not found."));
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const Center(child: Text("Invalid user data."));
        }

        final userModel = UserModel.fromJson(userData);
        final storeId = userModel.storeId;

        if (storeId.isEmpty) {
          return const Center(child: Text("Store not set up."));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .snapshots(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData || !storeSnap.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final store = StoreModel.fromJson(
                storeSnap.data!.data() as Map<String, dynamic>);

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, store),
                          const SizedBox(height: 24),
                          _buildRevenueHeroCard(context, store),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPerformanceGrid(context, store),
                                const SizedBox(height: 24),
                                _buildPayoutCard(context, store),
                                const SizedBox(height: 32),
                                _buildMostOrderedProducts(context, store),
                                const SizedBox(height: 32),
                                _buildRecentOrders(context, store),
                                const SizedBox(height: 48),
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

  // ──────────────────────────────────────────────
  // SECTION 1 — COMPACT HEADER (no status, no profile icon)
  // ──────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, StoreModel store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Store logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey100,
              image: store.logo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(store.logo),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(color: AppColors.grey200, width: 2),
            ),
            child: store.logo.isEmpty
                ? const Icon(Icons.storefront_rounded,
                    color: AppColors.grey400, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          // Greeting + Store Name + Verified
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_greeting()} 👋",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        store.storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (store.verified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF4A90D9), size: 17),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Notification bell only
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.textPrimary, size: 22),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HERO REVENUE CARD — gradient card with total revenue
  // ──────────────────────────────────────────────
  Widget _buildRevenueHeroCard(BuildContext context, StoreModel store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD66853), Color(0xFFE8956A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD66853).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Revenue",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "This Month",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "₹0",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            // Two mini-stats inside the hero card
            Row(
              children: [
                _buildHeroMiniStat(
                    Icons.shopping_bag_rounded, "Total Orders", "${store.totalOrders}"),
                const SizedBox(width: 24),
                _buildHeroMiniStat(
                    Icons.star_rounded, "Rating", store.rating > 0 ? store.rating.toStringAsFixed(1) : "New"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMiniStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // SECTION 2 — PERFORMANCE METRICS GRID
  // ──────────────────────────────────────────────
  Widget _buildPerformanceGrid(BuildContext context, StoreModel store) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayStartStr = todayStart.toIso8601String();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Performance",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('storeId', isEqualTo: store.storeId)
              .where('createdAt', isGreaterThanOrEqualTo: todayStartStr)
              .snapshots(),
          builder: (context, todaySnap) {
            final todayDocs = todaySnap.data?.docs ?? [];
            final todayOrders = todayDocs.length;
            double todayRevenue = 0;
            int pendingCount = 0;
            int deliveredToday = 0;
            for (final doc in todayDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final status = (d['orderStatus'] ?? '').toString().toLowerCase();
              final amount = (d['totalAmount'] ?? 0.0) as num;
              todayRevenue += amount;
              if (status == 'new' || status == 'accepted' || status == 'packed') pendingCount++;
              if (status == 'delivered') deliveredToday++;
            }
            final avgOrder = todayOrders > 0
                ? (todayRevenue / todayOrders).toStringAsFixed(0)
                : '0';

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('storeId', isEqualTo: store.storeId)
                  .snapshots(),
              builder: (context, prodSnap) {
                final productCount = prodSnap.data?.docs.length ?? 0;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    _buildMetricCard(
                      "Orders Today",
                      "$todayOrders",
                      Icons.shopping_bag_rounded,
                      const Color(0xFF4A90D9),
                      const Color(0xFFEBF3FB),
                    ),
                    _buildMetricCard(
                      "Revenue Today",
                      "₹${todayRevenue.toStringAsFixed(0)}",
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF2ECC71),
                      const Color(0xFFE8F8F0),
                    ),
                    _buildMetricCard(
                      "Pending Orders",
                      "$pendingCount",
                      Icons.pending_actions_rounded,
                      const Color(0xFFE67E22),
                      const Color(0xFFFDF2E9),
                    ),
                    _buildMetricCard(
                      "Delivered Today",
                      "$deliveredToday",
                      Icons.check_circle_rounded,
                      const Color(0xFF1ABC9C),
                      const Color(0xFFE8F6F3),
                    ),
                    _buildMetricCard(
                      "Products Live",
                      "$productCount",
                      Icons.inventory_2_rounded,
                      const Color(0xFF9B59B6),
                      const Color(0xFFF4ECF7),
                    ),
                    _buildMetricCard(
                      "Avg Order Value",
                      "₹$avgOrder",
                      Icons.analytics_rounded,
                      const Color(0xFFE74C3C),
                      const Color(0xFFFDEDED),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PAYOUT CARD — Weekly earnings & upcoming Sunday payout
  // ──────────────────────────────────────────────
  Widget _buildPayoutCard(BuildContext context, StoreModel store) {
    final now = DateTime.now();
    // Find the most recent Monday (start of this week)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    // Next Sunday
    final daysUntilSunday = 7 - now.weekday;
    final nextSunday = now.add(Duration(days: daysUntilSunday));
    final nextSundayStr =
        "${nextSunday.day} ${_monthName(nextSunday.month)}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('storeId', isEqualTo: store.storeId)
          .where('createdAt',
              isGreaterThanOrEqualTo: weekStartDay.toIso8601String())
          .snapshots(),
      builder: (context, snap) {
        double weeklyGross = 0;
        double onHold = 0;
        double released = 0;
        int deliveredCount = 0;
        int activeCount = 0;

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final status = (d['orderStatus'] ?? '').toString().toLowerCase();
            final amount = (d['totalAmount'] ?? 0.0) as num;
            weeklyGross += amount.toDouble();
            if (status == 'delivered') {
              // Assume 10% platform fee
              released += amount * 0.9;
              deliveredCount++;
            } else if (status != 'cancelled') {
              onHold += amount.toDouble();
              activeCount++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1A2E).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "💰 Earnings & Payout",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Payout: $nextSundayStr",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: _buildPayoutRow(
                    "This Week's Sales",
                    "₹${weeklyGross.toStringAsFixed(0)}",
                    Icons.bar_chart_rounded,
                    const Color(0xFFFFD700),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPayoutRow(
                      "On Hold 🔒",
                      "₹${onHold.toStringAsFixed(0)}",
                      Icons.lock_clock_rounded,
                      const Color(0xFFFF9F43),
                      subtitle:
                          "$activeCount active order${activeCount != 1 ? 's' : ''}",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPayoutRow(
                      "Ready to Earn",
                      "₹${released.toStringAsFixed(0)}",
                      Icons.check_circle_rounded,
                      const Color(0xFF55EFC4),
                      subtitle:
                          "$deliveredCount delivered",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "FreshGa holds payment until delivery. Payouts release every Sunday after our 10% platform fee.",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutRow(
    String label,
    String value,
    IconData icon,
    Color color, {
    String subtitle = '',
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // ──────────────────────────────────────────────
  // SECTION 3 — MOST ORDERED PRODUCTS
  // ──────────────────────────────────────────────
  Widget _buildMostOrderedProducts(BuildContext context, StoreModel store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Most Ordered",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "See All",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('storeId', isEqualTo: store.storeId)
              .limit(6)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                "Your homemade food journey starts here 🚀",
                "Add your first product and start growing your brand.",
                Icons.fastfood_outlined,
              );
            }

            final docs = snapshot.data!.docs;

            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Product Name';
                  final price = data['price'] ?? 0;
                  final List<dynamic> images = data['images'] ?? [];
                  final ordersCount = data['ordersCount'] ?? 0;

                  return Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            image: images.isNotEmpty
                                ? DecorationImage(
                                    image:
                                        NetworkImage(images.first.toString()),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: images.isEmpty
                              ? Center(
                                  child: Icon(Icons.fastfood_rounded,
                                      color: AppColors.grey300, size: 32))
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "$ordersCount orders",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "₹$price",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  // ──────────────────────────────────────────────
  // SECTION 4 — RECENT ORDERS PREVIEW
  // ──────────────────────────────────────────────
  Widget _buildRecentOrders(BuildContext context, StoreModel store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Orders",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "View All →",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('storeId', isEqualTo: store.storeId)
              .orderBy('createdAt', descending: true)
              .limit(4)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                "Your first customer order will appear here ❤️",
                "",
                Icons.receipt_long_outlined,
              );
            }

            final docs = snapshot.data!.docs;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data() as Map<String, dynamic>;
                    final customerName = data['customerName'] ?? 'Customer';
                    final amount = data['totalAmount'] ?? 0;
                    final itemsCount = data['itemsCount'] ?? 1;
                    final status = data['orderStatus'] ?? 'New';

                    Color statusColor = const Color(0xFFE67E22);
                    Color statusBg = const Color(0xFFFDF2E9);
                    if (status.toString().toLowerCase() == 'delivered') {
                      statusColor = const Color(0xFF2ECC71);
                      statusBg = const Color(0xFFE8F8F0);
                    }
                    if (status.toString().toLowerCase() == 'cancelled') {
                      statusColor = const Color(0xFFE74C3C);
                      statusBg = const Color(0xFFFDEDED);
                    }
                    if (status.toString().toLowerCase() == 'confirmed') {
                      statusColor = const Color(0xFF4A90D9);
                      statusBg = const Color(0xFFEBF3FB);
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Order icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text("🛒",
                                      style: TextStyle(fontSize: 20)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Customer + items
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "$itemsCount Item${itemsCount > 1 ? 's' : ''}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount + status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹$amount",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (index < docs.length - 1)
                          const Divider(
                              height: 1,
                              indent: 74,
                              endIndent: 16,
                              color: AppColors.grey200),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // REUSABLE EMPTY STATE
  // ──────────────────────────────────────────────
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
