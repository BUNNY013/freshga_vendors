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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildQuickActions(context),
                                const SizedBox(height: 32),
                                _buildPerformanceGrid(context, store),
                                const SizedBox(height: 28),
                                _buildPayoutCard(context, store),
                                const SizedBox(height: 28),
                                _buildMonthlyAllTimeStats(context, store),
                                const SizedBox(height: 32),
                                _buildMostOrderedProducts(context, store),
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
  // SECTION 1 — COMPACT HEADER
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      "Store Status: ",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      store.isActive ? "Live ✅" : "Offline",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: store.isActive
                            ? const Color(0xFF2ECC71)
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right Side: Notification bell only
          Container(
            decoration: const BoxDecoration(
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
  // SECTION 2 — QUICK ACTIONS
  // ──────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem("Add Product", Icons.add, () => context.push('/add-product')),
            _buildActionItem("View Orders", Icons.receipt_long_rounded, () {}),
            _buildActionItem("Edit Store", Icons.storefront_rounded, () => context.push('/edit-store')),
            _buildActionItem("Share Store", Icons.ios_share_rounded, () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.grey200, width: 1),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SECTION 3 — TODAY'S OVERVIEW (2x2 Grid)
  // ──────────────────────────────────────────────
  Widget _buildPerformanceGrid(BuildContext context, StoreModel store) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayStartStr = todayStart.toIso8601String();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Overview",
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
            
            for (final doc in todayDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final status = (d['orderStatus'] ?? '').toString().toLowerCase();
              final amount = (d['totalAmount'] ?? 0.0) as num;
              todayRevenue += amount;
              if (status == 'new' || status == 'accepted' || status == 'packed') pendingCount++;
            }

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
                      "Products Live",
                      "$productCount",
                      Icons.inventory_2_rounded,
                      const Color(0xFF9B59B6),
                      const Color(0xFFF4ECF7),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
  // PAYOUT CARD — Weekly hold / released + Sunday payout
  // ──────────────────────────────────────────────
  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  Widget _buildPayoutCard(BuildContext context, StoreModel store) {
    final now = DateTime.now();
    // Monday = start of this week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    // Upcoming Sunday
    final daysUntilSunday = 7 - now.weekday;
    final nextSunday = now.add(Duration(days: daysUntilSunday));
    final nextSundayStr = '${nextSunday.day} ${_monthName(nextSunday.month)}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('storeId', isEqualTo: store.storeId)
          .where('createdAt', isGreaterThanOrEqualTo: weekStartDay.toIso8601String())
          .snapshots(),
      builder: (context, snap) {
        double weeklyGross = 0;
        double onHold = 0;
        double released = 0;

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final status = (d['orderStatus'] ?? '').toString().toLowerCase();
            final amount = (d['totalAmount'] ?? 0.0) as num;
            if (status == 'cancelled') continue;
            weeklyGross += amount.toDouble();
            if (status == 'delivered') {
              released += amount.toDouble() * 0.90; // after 10% platform fee
            } else {
              onHold += amount.toDouble();
            }
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2340), Color(0xFF243060)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A2340).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 Earnings & Payout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Payout: $nextSundayStr',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Three metric columns
              Row(
                children: [
                  _buildPayoutMetric(
                    'This Week',
                    '₹${weeklyGross.toStringAsFixed(0)}',
                    const Color(0xFF7EB8FF),
                  ),
                  _buildPayoutDivider(),
                  _buildPayoutMetric(
                    '🔒 On Hold',
                    '₹${onHold.toStringAsFixed(0)}',
                    const Color(0xFFFFBB55),
                  ),
                  _buildPayoutDivider(),
                  _buildPayoutMetric(
                    '✅ Ready',
                    '₹${released.toStringAsFixed(0)}',
                    const Color(0xFF5DECA0),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Money from delivered orders (after 10% fee) is released every Sunday.',
                        style: const TextStyle(
                          color: Colors.white60,
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

  Widget _buildPayoutMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.15),
    );
  }

  // ──────────────────────────────────────────────
  // MONTHLY + ALL-TIME STATS
  // ──────────────────────────────────────────────
  Widget _buildMonthlyAllTimeStats(BuildContext context, StoreModel store) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthStartStr = monthStart.toIso8601String();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly & All-Time',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        // Monthly stream
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('storeId', isEqualTo: store.storeId)
              .where('createdAt', isGreaterThanOrEqualTo: monthStartStr)
              .snapshots(),
          builder: (context, monthSnap) {
            double monthRevenue = 0;
            int monthOrders = 0;
            int monthDelivered = 0;

            if (monthSnap.hasData) {
              for (final doc in monthSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final status = (d['orderStatus'] ?? '').toString().toLowerCase();
                final amount = (d['totalAmount'] ?? 0.0) as num;
                monthOrders++;
                monthRevenue += amount.toDouble();
                if (status == 'delivered') monthDelivered++;
              }
            }

            // All-time stream nested inside
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('storeId', isEqualTo: store.storeId)
                  .snapshots(),
              builder: (context, allSnap) {
                double allRevenue = 0;
                int allOrders = 0;
                int allDelivered = 0;

                if (allSnap.hasData) {
                  for (final doc in allSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = (d['orderStatus'] ?? '').toString().toLowerCase();
                    final amount = (d['totalAmount'] ?? 0.0) as num;
                    allOrders++;
                    allRevenue += amount.toDouble();
                    if (status == 'delivered') allDelivered++;
                  }
                }

                return Column(
                  children: [
                    // Monthly row
                    _buildStatsBanner(
                      label: '📅 This Month',
                      color: const Color(0xFFF0F4FF),
                      borderColor: const Color(0xFFD0DCFF),
                      accentColor: const Color(0xFF4A70D9),
                      items: [
                        _StatItem('Revenue', '₹${monthRevenue.toStringAsFixed(0)}'),
                        _StatItem('Orders', '$monthOrders'),
                        _StatItem('Delivered', '$monthDelivered'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // All-time row
                    _buildStatsBanner(
                      label: '🏆 All Time',
                      color: const Color(0xFFFFF7F0),
                      borderColor: const Color(0xFFFFD8B0),
                      accentColor: const Color(0xFFD66853),
                      items: [
                        _StatItem('Revenue', '₹${allRevenue.toStringAsFixed(0)}'),
                        _StatItem('Orders', '$allOrders'),
                        _StatItem('Delivered', '$allDelivered'),
                      ],
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

  Widget _buildStatsBanner({
    required String label,
    required Color color,
    required Color borderColor,
    required Color accentColor,
    required List<_StatItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => Column(
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: accentColor.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SECTION 4 — MOST ORDERED PRODUCTS
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
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('storeId', isEqualTo: store.storeId)
              .orderBy('ordersCount', descending: true)
              .limit(5)
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
                          color: Color(0x06000000),
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
                              ? const Center(
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
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Starting ₹$price",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
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

// Simple data class for the stats banner
class _StatItem {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);
}
