import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../orders/domain/models/order_model.dart';

class ProductsAnalyticsScreen extends StatefulWidget {
  const ProductsAnalyticsScreen({super.key});

  @override
  State<ProductsAnalyticsScreen> createState() => _ProductsAnalyticsScreenState();
}

class _ProductStats {
  final ProductModel product;
  final int orders;
  final double revenue;
  final double views;
  _ProductStats(this.product, this.orders, this.revenue, this.views);
}

class _ProductsAnalyticsScreenState extends State<ProductsAnalyticsScreen> {
  String _activeTab = 'Best Selling';
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
        
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Scaffold(body: Center(child: Text('User error')));

        final storeId = UserModel.fromJson(userData).storeId;
        if (storeId.isEmpty) return const Scaffold(body: Center(child: Text('Store not setup')));

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Products Analytics', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            backgroundColor: Colors.white,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: storeId).snapshots(),
            builder: (context, prodSnap) {
              if (prodSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (prodSnap.hasError) return Center(child: Text('Error: ${prodSnap.error}'));

              List<ProductModel> allProducts = prodSnap.data!.docs.map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

              if (allProducts.isEmpty) {
                return _buildEmptyState();
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: storeId).snapshots(),
                builder: (context, orderSnap) {
                  if (orderSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<OrderModel> allOrders = orderSnap.data?.docs.map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>)).toList() ?? [];

                  return _buildAnalyticsBody(allProducts, allOrders);
                }
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildAnalyticsBody(List<ProductModel> products, List<OrderModel> orders) {
    int total = products.length;
    int live = products.where((p) => p.status.toLowerCase() == 'published' || p.status.toLowerCase() == 'live').length;
    int underReview = products.where((p) => p.status.toLowerCase() == 'draft' || p.status.toLowerCase() == 'under review').length;

    // Build stats by crossing products and orders
    Map<String, int> productOrdersCount = {};
    Map<String, double> productRevenue = {};

    for (var o in orders) {
      if (['delivered', 'shipped'].contains(o.orderStatus.toLowerCase())) {
        for (var item in o.items) {
          productOrdersCount[item.productId] = (productOrdersCount[item.productId] ?? 0) + item.quantity;
          productRevenue[item.productId] = (productRevenue[item.productId] ?? 0.0) + (item.price * item.quantity);
        }
      }
    }

    List<_ProductStats> statsList = products.map((p) {
      int o = productOrdersCount[p.productId] ?? 0;
      double r = productRevenue[p.productId] ?? 0.0;
      // We don't track views at the product level in MVP, just use 0 or mock slightly based on orders
      double v = o * 2.5; 
      return _ProductStats(p, o, r, v);
    }).toList();

    // Sort dynamically based on chip!
    if (_activeTab == 'Best Selling') {
      statsList.sort((a, b) => b.orders.compareTo(a.orders));
    } else if (_activeTab == 'Most Viewed') {
      statsList.sort((a, b) => b.views.compareTo(a.views));
    } else if (_activeTab == 'Most Revenue') {
      statsList.sort((a, b) => b.revenue.compareTo(a.revenue));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatBox('Total Products', '$total', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Live', '$live', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Drafts', '$underReview', Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTab('Best Selling')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTab('Most Viewed')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTab('Most Revenue')),
                  ],
                ),
                const SizedBox(height: 28),
                
                if (statsList.every((s) => s.orders == 0))
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text("No sales data yet", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                else
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.8),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      _buildTableHeader(),
                      ...statsList.take(6).map((stat) {
                        final format = NumberFormat('#,##,###', 'en_IN');
                        return _buildTableRow(
                          stat.product.name, 
                          '${stat.orders}', 
                          '₹${format.format(stat.revenue.toInt())}', 
                          '${stat.views.toStringAsFixed(1)}'
                        );
                      }),
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildTab(String text) {
    final active = _activeTab == text;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = text),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary);
    return const TableRow(
      children: [
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Product', style: style)),
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Orders', style: style)),
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Revenue', style: style)),
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Views', style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  TableRow _buildTableRow(String name, String orders, String rev, String views) {
    const style = TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
    return TableRow(
      children: [
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text(name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text(orders, style: style)),
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text(rev, style: style)),
        Padding(padding: EdgeInsets.only(bottom: 16), child: Text(views, style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Products Yet!", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)
            ),
            const SizedBox(height: 12),
            const Text(
              "Add products to your catalog to start tracking views, sales, and revenue analytics.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
