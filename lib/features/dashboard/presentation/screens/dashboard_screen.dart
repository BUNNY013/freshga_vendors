import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../products/presentation/screens/product_list_screen.dart';
import '../../../orders/presentation/screens/orders_list_screen.dart';
import '../../../store/presentation/screens/store_management_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../store/providers/subscription_provider.dart';
import 'home_dashboard_view.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        final token = await messaging.getToken();
        if (token != null && FirebaseAuth.instance.currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'fcmTokens': FieldValue.arrayUnion([token])});
        }
      } catch (e) {
        debugPrint('Error setting up notifications: $e');
      }
    }
  }

  List<Widget> get _views => [
    HomeDashboardView(
      onNavigateTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ),
    const OrdersListScreen(),
    const ProductListScreen(),
    const StoreManagementScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isExpired = subProvider.currentSubscription?.isCompletelyExpired ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _views[_currentIndex]
      ),
      bottomNavigationBar: FirebaseAuth.instance.currentUser != null ? FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
        builder: (context, userSnap) {
          String storeId = '';
          if (userSnap.hasData && userSnap.data!.exists) {
            final data = userSnap.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              storeId = UserModel.fromJson(data).storeId;
            }
          }

          if (storeId.isEmpty) {
            return _buildNavigationBar(0); // 0 count fallback
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: storeId).snapshots(),
            builder: (context, ordersSnap) {
              final count = ordersSnap.data?.docs.where((d) {
                final map = d.data() as Map<String, dynamic>;
                final status = (map['orderStatus'] as String?)?.toLowerCase() ?? '';
                return ['new', 'accepted', 'packed', 'ready', 'shipped'].contains(status);
              }).length ?? 0;

              return _buildNavigationBar(count);
            },
          );
        },
      ) : _buildNavigationBar(0),
    );
  }

  Widget _buildNavigationBar(int newOrdersCount) {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {'icon': Icons.receipt_long_outlined, 'active': Icons.receipt_long, 'label': 'Orders'},
      {'icon': Icons.inventory_2_outlined, 'active': Icons.inventory_2, 'label': 'Products'},
      {'icon': Icons.storefront_outlined, 'active': Icons.storefront, 'label': 'Store'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'Profile'},
    ];

    return SafeArea(
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isSelected = _currentIndex == index;
          final item = items[index];
          final isOrders = index == 1;
          
          Widget icon = Icon(
            isSelected ? item['active'] as IconData : item['icon'] as IconData,
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
            size: 26,
          );

          if (isOrders) {
            icon = Badge(
              isLabelVisible: newOrdersCount > 0,
              label: Text('$newOrdersCount', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.error,
              textColor: Colors.white,
              offset: const Offset(4, -4),
              child: icon,
            );
          }

          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ));
  }

}
