import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';

class EarningsPayoutsScreen extends StatefulWidget {
  const EarningsPayoutsScreen({super.key});

  @override
  State<EarningsPayoutsScreen> createState() => _EarningsPayoutsScreenState();
}

class _EarningsPayoutsScreenState extends State<EarningsPayoutsScreen> {
  String _chartFilter = '30D';

  @override
  Widget build(BuildContext context) {
    // Dynamic Mock Data
    final totalEarnings = _chartFilter == '7D' ? 12450 : _chartFilter == '30D' ? 48750 : 145000;
    final orderAmount = _chartFilter == '7D' ? 14200 : _chartFilter == '30D' ? 54200 : 160000;
    final commission = _chartFilter == '7D' ? -1420 : _chartFilter == '30D' ? -5420 : -16000;
    final shipping = _chartFilter == '7D' ? 1100 : _chartFilter == '30D' ? 4000 : 12000;
    final refunds = _chartFilter == '7D' ? -430 : _chartFilter == '30D' ? -2030 : -6000;
    
    final List<String> labels = _chartFilter == '7D' ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'] 
                              : _chartFilter == '30D' ? ['May 14', 'May 21', 'May 28', 'Jun 4', 'Jun 11'] 
                              : ['M1', 'M2', 'M3'];
                              
    final List<FlSpot> spots = List.generate(labels.length, (index) {
       final base = totalEarnings * 0.1;
       final randomGrowth = (index + 1) * (totalEarnings / (labels.length * 1.5));
       return FlSpot(index.toDouble(), base + randomGrowth);
    });

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
            Row(
              children: [
                Expanded(child: _buildTopStatBox('Available Balance', '₹5,240', 'Ready for payout')),
                const SizedBox(width: 8),
                Expanded(child: _buildTopStatBox('Pending Settlement', '₹8,760', 'Will be settled soon')),
                const SizedBox(width: 8),
                Expanded(child: _buildTopStatBox('Next Payout', '16 Jun 2025', 'In 4 days')),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildChartCard(totalEarnings, labels, spots),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(child: _buildBreakdownBox('Order Amount', '₹${_format(orderAmount)}', Colors.black87)),
                const SizedBox(width: 8),
                Expanded(child: _buildBreakdownBox('Commission (10%)', '-₹${_format(commission.abs())}', Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildBreakdownBox('Shipping Collected', '₹${_format(shipping)}', Colors.black87)),
                const SizedBox(width: 8),
                Expanded(child: _buildBreakdownBox('Refunds', '-₹${_format(refunds.abs())}', Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildPayoutHistory(),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Download Statement', 
                    Icons.download_rounded, 
                    Colors.green.shade700, 
                    Colors.green.shade50
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'See All Transactions', 
                    Icons.chevron_right_rounded, 
                    Colors.green.shade700, 
                    Colors.green.shade50
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _format(int value) {
    if (value >= 1000) {
      String s = value.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return value.toString();
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

  Widget _buildChartCard(int totalEarnings, List<String> labels, List<FlSpot> spots) {
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
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: totalEarnings / 2, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
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
    return Container(
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
    );
  }

  Widget _buildPayoutHistory() {
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
              Text('View all', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 24),
          _buildPayoutRow('05 Jun 2025', '₹12,480', 'Paid', Colors.green),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.background)),
          _buildPayoutRow('22 May 2025', '₹9,650', 'Paid', Colors.green),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.background)),
          _buildPayoutRow('08 May 2025', '₹8,120', 'Paid', Colors.green),
        ],
      ),
    );
  }

  Widget _buildPayoutRow(String date, String amount, String status, MaterialColor color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(date, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
        Row(
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(status, style: TextStyle(color: color.shade700, fontSize: 11, fontWeight: FontWeight.w800)),
            )
          ],
        )
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon == Icons.download_rounded) ...[
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(width: 8),
            Icon(icon, color: textColor, size: 18),
          ] else ...[
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(width: 4),
            Icon(icon, color: textColor, size: 18),
          ]
        ],
      ),
    );
  }
}
