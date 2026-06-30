import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../orders/domain/models/order_model.dart';
import '../widgets/premium_line_chart_card.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  const RevenueAnalyticsScreen({super.key});

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  String _chartFilter = 'All'; // Default filter
  late Future<DocumentSnapshot> _userFuture;
  Stream<QuerySnapshot>? _ordersStream;

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
        if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Scaffold(body: Center(child: Text('User error')));

        final storeId = UserModel.fromJson(userData).storeId;
        if (storeId.isEmpty) return const Scaffold(body: Center(child: Text('Store not setup')));

        _ordersStream ??= FirebaseFirestore.instance
            .collection('orders')
            .where('storeId', isEqualTo: storeId)
            .orderBy('createdAt', descending: true)
            .snapshots();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Revenue', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            backgroundColor: Colors.white,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<OrderModel> allOrders = snapshot.data!.docs
                  .map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();

              // TEMPORARY: Inject mock data if DB is empty so we can test the UI
              if (allOrders.isEmpty) {
                allOrders = _generateMockOrders(storeId);
              }

              return _buildAnalyticsBody(allOrders);
            },
          ),
        );
      }
    );
  }

  Widget _buildAnalyticsBody(List<OrderModel> allOrders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allOrders.any((o) => o.orderId.startsWith('mock_')))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(child: Text("Displaying 150 injected Mock Orders for UI testing.", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                ],
              ),
            ),
          _buildTotalRevenueCard(allOrders),
          const SizedBox(height: 24),
          _buildRealTimeTrendChartCard(allOrders),
          const SizedBox(height: 24),
          _buildQuickStatsRow(allOrders),
          const SizedBox(height: 24),
          _buildRevenueByProduct(allOrders),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTotalRevenueCard(List<OrderModel> orders) {
    // Calculate total revenue for completed/delivered orders
    final completedOrders = orders.where((o) => o.orderStatus.toLowerCase() == 'delivered');
    double totalRevenue = completedOrders.fold(0.0, (sum, item) => sum + item.totalAmount);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Revenue', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Text('₹${NumberFormat('#,##0').format(totalRevenue)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('▲ 0% vs last 30 days', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_rounded, color: Colors.orange.shade600, size: 40),
          )
        ],
      ),
    );
  }

  Widget _buildRealTimeTrendChartCard(List<OrderModel> allOrders) {
    // 1. Filter orders based on _chartFilter
    DateTime now = DateTime.now();
    DateTime startDate;
    int days;

    switch (_chartFilter) {
      case 'Today': startDate = DateTime(now.year, now.month, now.day); days = 1; break;
      case '7D': startDate = now.subtract(const Duration(days: 7)); days = 7; break;
      case '90D': startDate = now.subtract(const Duration(days: 90)); days = 90; break;
      case 'All': startDate = DateTime(2020); days = 365; break;
      case '30D':
      default: startDate = now.subtract(const Duration(days: 30)); days = 30; break;
    }

    final filteredOrders = allOrders.where((o) => o.createdAt.isAfter(startDate) && o.orderStatus.toLowerCase() == 'delivered').toList();

    if (filteredOrders.isEmpty) {
      return PremiumLineChartCard(
        title: 'Revenue Trend',
        primaryMetricLabel: '₹',
        chartColor: Colors.orange.shade600,
        selectedFilter: _chartFilter,
        xLabels: const [],
        dataSpots: const [],
        onFilterChanged: (newFilter) {
          setState(() {
            _chartFilter = newFilter;
          });
        },
      );
    }

    // 2. Group by Date
    Map<String, double> groupedData = {};
    
    // Initialize map with empty days to ensure continuous line
    if (days <= 30) {
      for (int i = days - 1; i >= 0; i--) {
        DateTime d = now.subtract(Duration(days: i));
        String key = DateFormat('MMM d').format(d);
        groupedData[key] = 0.0;
      }
    } else {
      if (_chartFilter == 'All') {
         for (var order in filteredOrders) {
           String key = DateFormat('MMM yyyy').format(order.createdAt);
           groupedData[key] = 0.0; // initialize
         }
      }
    }

    // Populate data
    for (var order in filteredOrders) {
      String key = _chartFilter == 'All' 
          ? DateFormat('MMM yyyy').format(order.createdAt)
          : DateFormat('MMM d').format(order.createdAt);
      groupedData[key] = (groupedData[key] ?? 0.0) + order.totalAmount;
    }

    // 3. Convert to Chart format
    List<String> labels = groupedData.keys.toList();
    List<FlSpot> spots = [];
    
    for (int i = 0; i < labels.length; i++) {
      spots.add(FlSpot(i.toDouble(), groupedData[labels[i]]!));
    }

    // Removed fake fallback

    return PremiumLineChartCard(
      title: 'Revenue Trend',
      primaryMetricLabel: '₹',
      chartColor: Colors.orange.shade600,
      selectedFilter: _chartFilter,
      xLabels: labels,
      dataSpots: spots,
      onFilterChanged: (newFilter) {
        setState(() {
          _chartFilter = newFilter;
        });
      },
    );
  }

  Widget _buildQuickStatsRow(List<OrderModel> orders) {
    final completedOrders = orders.where((o) => o.orderStatus.toLowerCase() == 'delivered').toList();
    double totalRevenue = completedOrders.fold(0.0, (sum, item) => sum + item.totalAmount);
    double avgOrderValue = completedOrders.isEmpty ? 0 : totalRevenue / completedOrders.length;
    
    int totalOrderCount = orders.length;
    int refundedCount = orders.where((o) => o.orderStatus.toLowerCase() == 'refunded').length;

    return Row(
      children: [
        Expanded(child: _buildStatBox('Avg. Order Value', '₹${avgOrderValue.toInt()}', '▲ 0%')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('Orders', '$totalOrderCount', '▲ 0%')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('Refunded', '$refundedCount', '↓ 0%')),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, String trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: trend.contains('↓') ? Colors.red : Colors.green)),
        ],
      ),
    );
  }

  Widget _buildRevenueByProduct(List<OrderModel> orders) {
    // Dynamic aggregation by product
    Map<String, double> productRevenue = {};
    Map<String, int> productOrders = {};

    for (var order in orders.where((o) => o.orderStatus.toLowerCase() == 'delivered')) {
      for (var item in order.items) {
        productRevenue[item.productName] = (productRevenue[item.productName] ?? 0.0) + (item.price * item.quantity);
        productOrders[item.productName] = (productOrders[item.productName] ?? 0) + item.quantity;
      }
    }

    // Sort by top revenue
    var sortedProducts = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 for preview
    var topProducts = sortedProducts.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Products by Revenue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 24),
          if (topProducts.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No completed orders yet", style: TextStyle(color: Colors.grey))))
          else
            ...topProducts.asMap().entries.map((entry) {
              int index = entry.key;
              var prod = entry.value;
              String name = prod.key;
              double rev = prod.value;
              int count = productOrders[name] ?? 0;
              
              return Column(
                children: [
                  _buildProductRow(name, '₹${NumberFormat('#,##0').format(rev)}', '$count sold'),
                  if (index != topProducts.length - 1) 
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.grey.shade100)),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductRow(String name, String rev, String orders) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.fastfood, color: Colors.orange.shade600, size: 20),
            ),
            const SizedBox(width: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(rev, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 14)),
            const SizedBox(height: 2),
            Text(orders, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  List<OrderModel> _generateMockOrders(String storeId) {
    final now = DateTime.now();
    List<OrderModel> mockOrders = [];
    final statuses = ['Delivered', 'Delivered', 'Delivered', 'New', 'Accepted', 'Packed', 'Shipped', 'Cancelled', 'Refunded'];
    final productNames = ['Spicy Mango Pickle', 'Ghee Sweets', 'Organic Honey', 'Homemade Chips'];
    
    // Using a pseudo-random generator so the chart looks organic
    for (int i = 0; i < 150; i++) {
      int daysAgo = (i < 50) ? (i % 7) : (i % 90); 
      final orderDate = now.subtract(Duration(days: daysAgo, hours: (i * 7) % 24));
      final status = statuses[i % statuses.length];
      
      mockOrders.add(OrderModel(
        orderId: 'mock_$i',
        storeId: storeId,
        customerId: 'cust_$i',
        customerName: 'Mock Customer $i',
        items: [
          OrderItem(productId: 'p${i%4}', productName: productNames[i % 4], quantity: (i % 3) + 1, price: 250.0 + (i % 3)*50),
          if (i % 2 == 0) OrderItem(productId: 'p${(i+1)%4}', productName: productNames[(i+1) % 4], quantity: 1, price: 100.0),
        ],
        totalAmount: ((i % 5) + 1) * 350.0,
        paymentStatus: 'Paid',
        deliveryAddress: 'Mock Address',
        orderStatus: status,
        createdAt: orderDate,
        updatedAt: orderDate,
      ));
    }
    return mockOrders;
  }
}
