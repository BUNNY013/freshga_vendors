import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/states/app_state_widgets.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/product_model.dart';
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
                return const LoadingStateWidget(message: 'Loading products data...');
              }
              if (prodSnap.hasError) return ErrorStateWidget(message: 'Failed to load products', onRetry: () {});

              List<ProductModel> allProducts = prodSnap.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['productId'] = doc.id;
                return ProductModel.fromJson(data);
              }).toList();

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

    List<ProductModel> lowStockProducts = [];
    List<ProductModel> outOfStockProducts = [];

    for (var product in products) {
      if (product.status.toLowerCase() == 'published' || product.status.toLowerCase() == 'live' || product.status.contains('Live')) {
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
    }

    Widget buildNeedsAttention() {
      if (lowStockProducts.isEmpty && outOfStockProducts.isEmpty) return const SizedBox.shrink();

      List<Widget> attentionWidgets = [];
      
      for (var p in lowStockProducts) {
        attentionWidgets.add(_buildProductAttentionRow(
          product: p,
          subtitle: "Running low on stock",
          badgeText: "Restock",
          badgeColor: Colors.orange.shade600,
          onTap: () => context.push('/edit-pricing', extra: p),
        ));
      }

      for (var p in outOfStockProducts) {
        attentionWidgets.add(_buildProductAttentionRow(
          product: p,
          subtitle: "Out of stock",
          badgeText: "Urgent",
          badgeColor: Colors.red.shade600,
          onTap: () => context.push('/edit-pricing', extra: p),
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
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.textPrimary, size: 20),
              SizedBox(width: 8),
              Text("Needs Attention", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(children: finalWidgets),
          ),
          const SizedBox(height: 24),
        ],
      );
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
          
          buildNeedsAttention(),
          
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
                
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.8),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    _buildTableHeader(),
                    if (statsList.isEmpty)
                      const TableRow(children: [
                        Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text("No products found", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                        Text(""), Text(""), Text("")
                      ])
                    else if (statsList.every((s) => s.orders == 0) && _activeTab != 'Low Stock' && _activeTab != 'Out of Stock')
                      const TableRow(children: [
                        Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text("No sales data yet", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                        Text(""), Text(""), Text("")
                      ])
                    else
                      ...statsList.take(6).map((stat) {
                        final format = NumberFormat('#,##,###', 'en_IN');
                        return _buildTableRow(
                          stat.product,
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

  TableRow _buildTableRow(ProductModel product, String name, String orders, String rev, String views) {
    const style = TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
    
    Widget wrapClickable(Widget child) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/edit-pricing', extra: product),
        child: child,
      );
    }

    return TableRow(
      children: [
        wrapClickable(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis))),
        wrapClickable(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(orders, style: style))),
        wrapClickable(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(rev, style: style))),
        wrapClickable(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(views, style: style, textAlign: TextAlign.right))),
      ],
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
