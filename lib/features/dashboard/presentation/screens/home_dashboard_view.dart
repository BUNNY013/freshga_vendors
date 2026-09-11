import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/user_model.dart';
import '../../../../features/store/domain/models/store_model.dart';
import '../../../../features/store/providers/subscription_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/notifications/providers/notification_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/product_model.dart';


class HomeDashboardView extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeDashboardView({super.key, this.onNavigateTab});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _payoutKey = GlobalKey();
  bool _hasCheckedTutorial = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkDashboardTutorial() async {
    if (_hasCheckedTutorial) return;
    _hasCheckedTutorial = true;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_home_tutorial') ?? false;
    
    if (!hasSeenTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([_headerKey, _payoutKey]);
        }
      });
      await prefs.setBool('has_seen_home_tutorial', true);
    }
  }

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
              _checkDashboardTutorial();
            });

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubscriptionBanner(context),
                          if (store.isSuspended) _buildSuspensionBanner(context),
                          Showcase(
                            key: _headerKey,
                            title: '1 of 2: Store Timings',
                            description: 'Check if your store is currently Open or Closed here.',
                            tooltipBackgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            targetPadding: const EdgeInsets.all(8),
                            targetShapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            overlayOpacity: 0.5,
                            tooltipActions: [
                              TooltipActionButton(
                                type: TooltipDefaultActionType.skip,
                                name: 'Skip Tutorial',
                                textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                name: 'Next',
                                backgroundColor: Colors.white,
                                textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                            child: _buildGreetingHeader(context, store),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Showcase(
                                  key: _payoutKey,
                                  title: '2 of 2: Daily Payouts',
                                  description: 'Track your daily earnings and next payout date here.',
                                  tooltipBackgroundColor: AppColors.primary,
                                  textColor: Colors.white,
                                  targetPadding: const EdgeInsets.all(4),
                                  targetShapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  overlayOpacity: 0.5,
                                  tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      name: 'Finish',
                                      backgroundColor: Colors.white,
                                      textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  child: _buildPayoutMetricsCard(context, store),
                                ),
                                const SizedBox(height: 24),
                                _buildTodaysOverview(context, store),
                                const SizedBox(height: 28),
                                _buildNeedsAttention(context, store),
                                const SizedBox(height: 28),
                                _buildQuickActions(context),
                                const SizedBox(height: 24),
                                _buildPremiumFooter(context),
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

  // 0. Subscription Banner
  Widget _buildSubscriptionBanner(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final sub = subProvider.currentSubscription;
        if (sub == null || sub.isPaidActive) return const SizedBox.shrink(); // Don't annoy active paying users

        Color bgColor;
        Color iconColor;
        IconData icon;
        String title;
        String btnText;

        if (sub.isTrialActive) {
          final daysLeft = sub.trialEndsAt.difference(DateTime.now()).inDays;
          
          // Only show banner if 7 days or less are remaining
          if (daysLeft > 7) return const SizedBox.shrink();
          
          bgColor = const Color(0xFFFDE68A);
          iconColor = const Color(0xFFD97706);
          icon = Icons.timer_outlined;
          title = "$daysLeft Days left in Free Trial";
          btnText = "View Plans";
        } else if (sub.isInGracePeriod) {
          final hoursLeft = sub.currentPeriodEnd!.add(const Duration(days: 3)).difference(DateTime.now()).inHours;
          bgColor = Colors.orange.shade100;
          iconColor = Colors.orange.shade900;
          icon = Icons.warning_amber_rounded;
          title = "$hoursLeft hours left before your store goes offline. Pay now!";
          btnText = "Renew";
        } else if (sub.isCompletelyExpired) {
          bgColor = Colors.red.shade100;
          iconColor = Colors.red.shade900;
          icon = Icons.error_outline;
          title = "Store Offline. You cannot receive orders.";
          btnText = "Pay Now";
        } else {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: bgColor),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/subscription');
                },
                style: TextButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(btnText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
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
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: store.isSuspended ? Colors.red.shade50 : (store.isActive ? Colors.green.shade50 : Colors.orange.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: store.isSuspended ? Colors.red.shade200 : (store.isActive ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: store.isSuspended ? Colors.red.shade600 : (store.isActive ? Colors.green.shade600 : Colors.orange.shade600),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.isSuspended ? "Suspended" : (store.isActive ? "Live" : "Vacation"),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: store.isSuspended ? Colors.red.shade700 : (store.isActive ? Colors.green.shade700 : Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        .snapshots(),
      builder: (context, snapshot) {
        double pendingSettlement = 0;
        double availableBalance = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final payoutStatus = (data['payoutStatus'] ?? 'pending').toString().toLowerCase();
            if (payoutStatus != 'pending') continue;

            final status = (data['orderStatus'] ?? '').toString().toLowerCase();
            final subTotal = (data['subTotal'] ?? 0.0) as num;
            final deliveryFee = (data['deliveryFee'] ?? 0.0) as num;
            
            if (['new', 'accepted', 'packed', 'ready', 'shipped'].contains(status)) {
              pendingSettlement += (subTotal + deliveryFee);
            } else if (status == 'delivered') {
              availableBalance += (subTotal + deliveryFee);
            }
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
                          Text("Pending Settlement", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("₹${pendingSettlement.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text("Orders in progress", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
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
              
              // Only count revenue for delivered orders
              if (status == 'delivered') {
                todayRevenue += amount;
              }
              
              if (status == 'new' || status == 'accepted' || status == 'packed') pendingCount++;
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: store.storeId).snapshots(),
              builder: (context, prodSnap) {
                final productCount = prodSnap.data?.docs.length ?? 0;

                return Consumer<DashboardProvider>(
                  builder: (context, dashboard, _) {
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.3,
                      children: [
                        _buildOverviewCard(context, "Orders Today", "$todayOrders", Colors.green, '/analytics/orders'),
                        _buildOverviewCard(context, "Revenue Today", "₹${todayRevenue.toStringAsFixed(0)}", Colors.orange, '/analytics/revenue'),
                        _buildOverviewCard(context, "Pending Orders", "${dashboard.pendingOrdersCount}", Colors.orange, '/analytics/orders'),
                        _buildOverviewCard(context, "Products Live", "$productCount", Colors.purple, '/analytics/products', lowStockCount: dashboard.lowStockCount, outOfStockCount: dashboard.outOfStockCount),
                        _buildOverviewCard(context, "Followers", "${store.followers}", Colors.blue, '/analytics/followers', showChevron: true),
                        _buildOverviewCard(context, "Store Rating", store.totalReviews < 5 ? "New" : store.rating.toStringAsFixed(1), Colors.orange, '/analytics/rating', showChevron: true),
                      ],
                    );
                  }
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, Color color, String route, {bool showChevron = false, String? trend, int? lowStockCount, int? outOfStockCount}) {
    final hasTrend = trend != null && trend.isNotEmpty;
    final isPositive = hasTrend && (trend.contains('▲') || trend.contains('+') || trend == 'Excellent');
    final trendColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    String displayTrend = hasTrend ? trend.replaceAll('▲ ', '').replaceAll('↓ ', '').replaceAll('+', '').replaceAll('-', '') : '';
    final IconData trendIcon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return GestureDetector(
      onTap: route.isEmpty ? null : () => context.push(route),
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
            if (title == "Products Live" && (lowStockCount != null && outOfStockCount != null))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (lowStockCount > 0)
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text("$lowStockCount Low", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  if (outOfStockCount > 0)
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text("$outOfStockCount Out", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  if (lowStockCount == 0 && outOfStockCount == 0)
                     Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text("All Good", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              )
            else if (hasTrend)
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
            else if (showChevron)
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right, color: Colors.black54, size: 18),
              )
          ],
        ),
      ),
    );
  }

  // 4. Needs Attention
  Widget _buildNeedsAttention(BuildContext context, StoreModel store) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: store.storeId).snapshots(),
      builder: (context, prodSnap) {
        final productCount = prodSnap.data?.docs.length ?? 0;
        
        List<ProductModel> lowStockProducts = [];
        List<ProductModel> outOfStockProducts = [];

        if (prodSnap.hasData) {
           for (var doc in prodSnap.data!.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                data['productId'] = doc.id;
                final product = ProductModel.fromJson(data);
                
                if (product.status.contains('Live')) {
                  if (product.variants.isNotEmpty) {
                    final isOutOfStock = product.variants.any((v) => v.manageStock && v.stock <= 0);
                    final isLowStock = product.variants.any((v) => v.manageStock && v.stock > 0 && v.stock <= 5);

                    if (isOutOfStock) {
                      outOfStockProducts.add(product);
                    } else if (isLowStock) {
                      lowStockProducts.add(product);
                    }
                  }
                }
              } catch (e) {
                // Ignore parse error
              }
           }
        }

        return Consumer<DashboardProvider>(
          builder: (context, dashboard, child) {
            final pendingCount = dashboard.pendingOrdersCount;
            final expiringCount = dashboard.expiringOrdersCount;
            final lowStockCount = lowStockProducts.length;
            final outOfStockCount = outOfStockProducts.length;

            final allClear = pendingCount == 0 && lowStockCount == 0 && outOfStockCount == 0 && expiringCount == 0;
            final isNewStore = productCount == 0 && store.totalOrders == 0;

            List<Widget> attentionWidgets = [];
            
            if (expiringCount > 0) {
              attentionWidgets.add(_buildAttentionRow(
                icon: Icons.timer_outlined,
                iconColor: Colors.red.shade700,
                title: "$expiringCount orders expiring soon!",
                subtitle: "Accept immediately to avoid cancellation",
                badgeText: "URGENT",
                badgeColor: Colors.red.shade800,
                onTap: () {
                  if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                  else context.go('/dashboard', extra: 1);
                },
              ));
            }
            
            if (pendingCount > 0) {
              attentionWidgets.add(_buildAttentionRow(
                icon: Icons.assignment,
                iconColor: Colors.orange.shade700,
                title: "$pendingCount orders need processing",
                subtitle: "Dispatch as soon as possible",
                badgeText: "High Priority",
                badgeColor: Colors.red.shade600,
                onTap: () {
                  if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                  else context.go('/dashboard', extra: 1);
                },
              ));
            }

            for (var p in lowStockProducts) {
              attentionWidgets.add(_buildProductAttentionRow(
                product: p,
                subtitle: "Running low on stock",
                badgeText: "Restock",
                badgeColor: Colors.orange.shade600,
                onTap: () {
                  context.push('/edit-pricing', extra: p);
                },
              ));
            }

            for (var p in outOfStockProducts) {
              attentionWidgets.add(_buildProductAttentionRow(
                product: p,
                subtitle: "Out of stock",
                badgeText: "Urgent",
                badgeColor: Colors.red.shade600,
                onTap: () {
                  context.push('/edit-pricing', extra: p);
                },
              ));
            }

            List<Widget> finalWidgets = [];
            for (int i = 0; i < attentionWidgets.length; i++) {
              finalWidgets.add(attentionWidgets[i]);
              if (i < attentionWidgets.length - 1) {
                finalWidgets.add(Divider(height: 1, indent: 64, color: Colors.grey.shade100));
              }
            }

            return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isNewStore ? Icons.waving_hand_rounded : (allClear ? Icons.check_circle_outline : Icons.notifications_active_outlined), 
                      color: isNewStore ? Colors.orange : (allClear ? Colors.green : AppColors.textPrimary), 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isNewStore ? "Welcome!" : (allClear ? "All Caught Up!" : "Needs Attention"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isNewStore)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.storefront_rounded, color: Colors.orange.shade400, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      "Let's get your store ready!",
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange.shade800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Add your first product to start selling.",
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (allClear)
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
                  children: finalWidgets,
                ),
              ),
          ],
        );
          },
        );
      },
    );
  }

  Widget _buildAttentionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAttentionRow({
    required ProductModel product,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image: product.images.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover)
                  : null,
              ),
              child: product.images.isEmpty ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor, letterSpacing: 0.3),
              ),
            ),
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionBtn(context, "Add Product", Icons.add_circle, Colors.green, () => context.push('/add-product')),
            _buildQuickActionBtn(context, "Orders", Icons.assignment, Colors.orange, () => context.push('/analytics/orders')),
            _buildQuickActionBtn(context, "Subscription", Icons.workspace_premium, Colors.purple, () => context.push('/subscription')),
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
  Widget _buildPremiumFooter(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final sub = subProvider.currentSubscription;
        if (sub == null || !sub.isPaidActive) return const SizedBox.shrink();
        
        final formattedDate = DateFormat('MMMM d, yyyy').format(sub.currentPeriodEnd!);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFFC084FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "FreshGa Premium Member",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9333EA),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Renews on $formattedDate",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/subscription'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF9333EA)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
