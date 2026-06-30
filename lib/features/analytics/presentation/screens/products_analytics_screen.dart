import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../products/domain/models/product_model.dart';

class ProductsAnalyticsScreen extends StatefulWidget {
  const ProductsAnalyticsScreen({super.key});

  @override
  State<ProductsAnalyticsScreen> createState() => _ProductsAnalyticsScreenState();
}

class _ProductsAnalyticsScreenState extends State<ProductsAnalyticsScreen> {
  late Future<DocumentSnapshot> _userFuture;
  Stream<QuerySnapshot>? _productsStream;
  String _activeTab = 'Best Selling';

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

        _productsStream ??= FirebaseFirestore.instance
            .collection('products')
            .where('storeId', isEqualTo: storeId)
            .snapshots();

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
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<ProductModel> allProducts = snapshot.data!.docs
                  .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();

              // TEMPORARY: Inject mock data if DB is empty so we can test the UI
              if (allProducts.isEmpty) {
                allProducts = _generateMockProducts(storeId);
              }

              return _buildAnalyticsBody(allProducts);
            },
          ),
        );
      }
    );
  }

  Widget _buildAnalyticsBody(List<ProductModel> products) {
    int total = products.length;
    int live = products.where((p) => p.status.toLowerCase() == 'published' || p.status.toLowerCase() == 'live').length;
    int underReview = products.where((p) => p.status.toLowerCase() == 'draft' || p.status.toLowerCase() == 'under review').length;

    // Map to stats for dynamic sorting
    List<_ProductStats> statsList = products.map((p) {
      // Generate stable mock analytics based on ID hash
      int o = (p.productId.hashCode.abs() % 350) + 10;
      double r = o * p.price;
      double v = (p.name.hashCode.abs() % 50) / 10.0 + 1.5;
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
          if (products.any((p) => p.productId.startsWith('mock_')))
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.science, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(child: Text("Displaying mock products data for UI testing.", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13))),
                ],
              ),
            ),
            
          Row(
            children: [
              Expanded(child: _buildStatBox('Total Products', '$total', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Live', '$live', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Under Review', '$underReview', Colors.orange)),
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
                
                // MOCK Best Selling List matching UI reference
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
                        '${stat.views.toStringAsFixed(1)}K'
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
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(name, style: style)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(orders, style: style)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(rev, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(views, style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  List<ProductModel> _generateMockProducts(String storeId) {
    final now = DateTime.now();
    List<ProductModel> mockProducts = [];
    final random = Random();
    
    for (int i = 0; i < 45; i++) {
      mockProducts.add(ProductModel(
        productId: 'mock_p$i',
        storeId: storeId,
        name: 'Mock Product $i',
        shortDescription: 'Desc',
        description: 'Desc',
        price: 250.0 + (i % 4) * 150.0, // Diverse prices for varied revenue sorting
        weight: '500g',
        shelfLife: '6 Months',
        ingredients: ['x', 'y'],
        category: 'Pickles',
        tags: [],
        stock: 50,
        images: [],
        status: i < 35 ? 'Published' : 'Draft',
        createdAt: now,
        updatedAt: now,
      ));
    }
    return mockProducts;
  }
}

class _ProductStats {
  final ProductModel product;
  final int orders;
  final double revenue;
  final double views;
  
  _ProductStats(this.product, this.orders, this.revenue, this.views);
}
