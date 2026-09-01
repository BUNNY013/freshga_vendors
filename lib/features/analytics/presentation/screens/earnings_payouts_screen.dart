import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../orders/domain/models/order_model.dart';
import 'payout_details_screen.dart';

class EarningsPayoutsScreen extends StatefulWidget {
  const EarningsPayoutsScreen({super.key});

  @override
  State<EarningsPayoutsScreen> createState() => _EarningsPayoutsScreenState();
}

class _EarningsPayoutsScreenState extends State<EarningsPayoutsScreen> {
  String _chartFilter = '30D';
  late Future<DocumentSnapshot> _userFuture;
  late Future<QuerySnapshot> _bankFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _bankFuture = FirebaseFirestore.instance.collection('supplierApplications').where('userId', isEqualTo: user.uid).limit(1).get();
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

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('storeId', isEqualTo: storeId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
            }

            final docs = snapshot.data?.docs ?? [];
            List<OrderModel> allOrders = docs.map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

            return _buildScaffold(allOrders, storeId);
          },
        );
      }
    );
  }

  Widget _buildScaffold(List<OrderModel> allOrders, String storeId) {
    // 1. Calculate Balances
    double availableBalance = 0;
    double pendingSettlement = 0;
    
    for (var o in allOrders) {
      if (o.payoutStatus.toLowerCase() == 'pending') {
        final amount = o.subTotal + o.deliveryFee;
        if (o.orderStatus.toLowerCase() == 'delivered') {
          availableBalance += amount;
        } else if (['new', 'accepted', 'packed', 'ready', 'shipped'].contains(o.orderStatus.toLowerCase())) {
          pendingSettlement += amount;
        }
      }
    }

    // 2. Next Payout Date
    DateTime now = DateTime.now();
    int daysUntilMonday = 8 - now.weekday;
    if (daysUntilMonday == 8) daysUntilMonday = 1;
    DateTime nextPayoutDate = now.add(Duration(days: daysUntilMonday));
    String formattedNextPayout = "${DateFormat('MMM').format(nextPayoutDate)} ${nextPayoutDate.day}, ${nextPayoutDate.year}";

    // 3. Filter Orders by Date
    DateTime startDate;
    int days;
    switch (_chartFilter) {
      case '7D': startDate = now.subtract(const Duration(days: 7)); days = 7; break;
      case 'All': startDate = DateTime(2020); days = 365; break;
      case '30D':
      default: startDate = now.subtract(const Duration(days: 30)); days = 30; break;
    }
    
    final filteredOrders = allOrders.where((o) => o.createdAt.isAfter(startDate)).toList();
    
    double totalEarnings = 0;
    double orderAmount = 0;
    double commission = 0;
    double shipping = 0;
    double refunds = 0;

    Map<String, double> groupedData = {};
    if (days <= 30) {
      for (int i = days - 1; i >= 0; i--) {
        String key = DateFormat('MMM d').format(now.subtract(Duration(days: i)));
        groupedData[key] = 0.0;
      }
    }

    for (var o in filteredOrders) {
      if (o.orderStatus.toLowerCase() == 'delivered' || o.orderStatus.toLowerCase() == 'shipped') {
        orderAmount += o.subTotal;
        shipping += o.deliveryFee;
        commission += 0; // Vendor pays 0 commission
        totalEarnings += (o.subTotal + o.deliveryFee);

        if (days <= 30) {
          String key = DateFormat('MMM d').format(o.createdAt);
          if (groupedData.containsKey(key)) {
            groupedData[key] = groupedData[key]! + (o.subTotal + o.deliveryFee);
          }
        }
      } else if (o.orderStatus.toLowerCase() == 'declined' || o.orderStatus.toLowerCase() == 'cancelled') {
        refunds += o.totalAmount;
      }
    }

    List<String> labels = [];
    List<FlSpot> spots = [];
    
    if (days <= 30) {
      int index = 0;
      groupedData.forEach((key, value) {
        if (days == 7 || index % 6 == 0) labels.add(key);
        else labels.add("");
        spots.add(FlSpot(index.toDouble(), value));
        index++;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Earnings & Payouts', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBankCardSection(storeId),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildTopStatBox('Available Balance', '₹${_format(availableBalance)}', 'Ready for payout')),
                const SizedBox(width: 8),
                Expanded(child: _buildTopStatBox('Pending Settlement', '₹${_format(pendingSettlement)}', 'Will be settled soon')),
                const SizedBox(width: 8),
                Expanded(child: _buildTopStatBox('Next Payout', formattedNextPayout, 'In $daysUntilMonday days')),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildChartCard(totalEarnings, labels, spots),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(child: _buildBreakdownBox('Order Amount', '₹${_format(orderAmount)}', Colors.black87)),
                const SizedBox(width: 8),
                Expanded(child: _buildBreakdownBox('Shipping Collected', '₹${_format(shipping)}', Colors.black87)),
                const SizedBox(width: 8),
                Expanded(child: _buildBreakdownBox('Refunds', '-₹${_format(refunds)}', Colors.red.shade700)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildPayoutHistory(storeId),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _format(double value) {
    if (value >= 1000) {
      String s = value.toStringAsFixed(0);
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildTopStatBox(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBreakdownBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildChartCard(double totalEarnings, List<String> labels, List<FlSpot> spots) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Earnings Overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              _buildFilterDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Earnings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('₹${_format(totalEarnings)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: spots.isEmpty || spots.every((s) => s.y == 0)
                      ? Center(child: Text("No earnings yet", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)))
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: totalEarnings > 0 ? (totalEarnings / 2).clamp(1, double.infinity) : 100, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text('₹${(value / 1000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(labels[index], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.green.shade600,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: Colors.green.shade600, strokeWidth: 2, strokeColor: Colors.white)),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(colors: [Colors.green.shade600.withOpacity(0.2), Colors.green.shade600.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _chartFilter = val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '7D', child: Text('Last 7 Days')),
        const PopupMenuItem(value: '30D', child: Text('Last 30 Days')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_chartFilter, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistory(String storeId) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payout History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payouts')
                .where('storeId', isEqualTo: storeId)
                .where('status', isEqualTo: 'completed')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No payouts yet", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final amount = data['amount'] ?? 0;
                  final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VendorPayoutDetailsScreen(payoutData: data)),
                      );
                    },
                    child: _buildPayoutRow(DateFormat('dd MMM yyyy').format(date), '₹${_format(amount.toDouble())}', 'Paid', Colors.green),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutRow(String date, String amount, String status, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet, color: color.shade700, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payout to Bank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: color.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBankCardSection(String storeId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future: _bankFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final bankDetails = data['bankDetails'] as Map<String, dynamic>?;

        if (bankDetails == null) {
          return const SizedBox.shrink();
        }

        final bankName = bankDetails['bankName'] ?? 'Unknown Bank';
        final accountHolder = bankDetails['accountHolderName'] ?? 'Unknown Bank';
        final accountNumber = bankDetails['accountNumber']?.toString() ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bankUpdateRequests')
              .where('userId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .snapshots(),
          builder: (context, pendingSnapshot) {
            final hasPendingRequest = pendingSnapshot.hasData && pendingSnapshot.data!.docs.isNotEmpty;
            final pendingData = hasPendingRequest ? pendingSnapshot.data!.docs.first.data() as Map<String, dynamic> : null;
            final pendingId = hasPendingRequest ? pendingSnapshot.data!.docs.first.id : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Linked Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.3),
                    blurRadius: 16,
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
                      Expanded(
                        child: Text(
                          bankName, 
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      accountNumber, 
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACCOUNT HOLDER', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(accountHolder.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
                    ],
                  )
                ],
              ),
            ),
            if (hasPendingRequest && pendingData != null) ...[
              const SizedBox(height: 16),
              _buildPendingReviewCard(pendingData['requestedBankDetails'] as Map<String, dynamic>, pendingId!),
            ],
          ],
        );
      },
    );
      },
    );
  }

  Widget _buildPendingReviewCard(Map<String, dynamic> details, String requestId) {
    final bankName = details['bankName'] ?? 'Unknown Bank';
    final accountNumber = details['accountNumber']?.toString() ?? '';
    final maskedAccount = accountNumber.length > 4 ? '•••• ${accountNumber.substring(accountNumber.length - 4)}' : '••••';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending_actions_rounded, size: 14, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text('Pending Approval', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  await FirebaseFirestore.instance.collection('bankUpdateRequests').doc(requestId).delete();
                },
                child: Text('Cancel Request', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.amber.shade200)),
                child: Icon(Icons.account_balance, color: Colors.amber.shade700, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    Text(maskedAccount, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
