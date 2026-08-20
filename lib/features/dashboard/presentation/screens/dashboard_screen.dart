import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const HomeDashboardView(),
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
      body: SafeArea(
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
                return (map['orderStatus'] as String?)?.toLowerCase() == 'new';
              }).length ?? 0;

              return _buildNavigationBar(count);
            },
          );
        },
      ) : _buildNavigationBar(0),
    );
  }

  Widget _buildNavigationBar(int newOrdersCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.home_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.home)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              child: Badge(
                isLabelVisible: newOrdersCount > 0,
                label: Text('$newOrdersCount'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              child: Badge(
                isLabelVisible: newOrdersCount > 0,
                label: Text('$newOrdersCount'),
                child: const Icon(Icons.receipt_long),
              ),
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.inventory_2_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.inventory_2)),
            label: 'Products',
          ),
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.storefront_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.storefront)),
            label: 'Store',
          ),
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.person_outline)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.person)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}
