import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/premium_line_chart_card.dart';

class StoreViewsAnalyticsScreen extends StatefulWidget {
  const StoreViewsAnalyticsScreen({super.key});

  @override
  State<StoreViewsAnalyticsScreen> createState() => _StoreViewsAnalyticsScreenState();
}

class _StoreViewsAnalyticsScreenState extends State<StoreViewsAnalyticsScreen> {
  String _chartFilter = '30D';

  @override
  Widget build(BuildContext context) {
    // Dynamic Mock Data Injection based on selected filter
    final int profileViews = _chartFilter == '7D' ? 420 : _chartFilter == '30D' ? 3420 : _chartFilter == '90D' ? 12450 : 25800;
    final int uniqueVisitors = _chartFilter == '7D' ? 280 : _chartFilter == '30D' ? 2180 : _chartFilter == '90D' ? 8100 : 16400;
    final String convRate = _chartFilter == '7D' ? '5.2%' : _chartFilter == '30D' ? '6.4%' : _chartFilter == '90D' ? '7.1%' : '6.8%';
    
    final List<String> labels = _chartFilter == '7D' ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'] 
                              : _chartFilter == '30D' ? ['May 14', 'May 21', 'May 28', 'Jun 4', 'Jun 11'] 
                              : _chartFilter == '90D' ? ['M1', 'M2', 'M3'] 
                              : ['2023', '2024'];
                              
    final List<FlSpot> spots = List.generate(labels.length, (index) {
       final base = profileViews * 0.1;
       final randomGrowth = (index + 1) * (profileViews / (labels.length * 2));
       return FlSpot(index.toDouble(), base + randomGrowth);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Store Views Analytics', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.science, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(child: Text("Displaying dynamic mock analytics for UI testing.", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13))),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildStatBox('Profile Views', '${_formatNumber(profileViews)}', '▲ 16.3%', Colors.black87)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox('Unique Visitors', '${_formatNumber(uniqueVisitors)}', '▲ 15.1%', Colors.black87)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox('Conversion Rate', convRate, '▲ 1.2%', Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),
            
            PremiumLineChartCard(
              title: 'Views Trend',
              primaryMetricLabel: 'Views',
              chartColor: Colors.green.shade600,
              selectedFilter: _chartFilter,
              xLabels: labels,
              dataSpots: spots,
              onFilterChanged: (newFilter) {
                setState(() => _chartFilter = newFilter);
              },
            ),
            const SizedBox(height: 24),
            
            _buildTrafficSourcesCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    final format = NumberFormat('#,##,###', 'en_IN');
    return format.format(number);
  }

  Widget _buildStatBox(String title, String value, String trend, Color color) {
    final isPositive = trend.contains('▲');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? Colors.green : Colors.red, size: 10),
              const SizedBox(width: 4),
              Text(
                trend.replaceAll('▲ ', '').replaceAll('↓ ', ''), 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isPositive ? Colors.green : Colors.red)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrafficSourcesCard() {
    // Dynamic values based on _chartFilter
    final search = _chartFilter == '7D' ? 52 : _chartFilter == '90D' ? 40 : 45;
    final direct = _chartFilter == '7D' ? 22 : _chartFilter == '90D' ? 35 : 30;
    final categories = _chartFilter == '7D' ? 12 : _chartFilter == '90D' ? 18 : 15;
    final recommendations = _chartFilter == '7D' ? 8 : _chartFilter == '90D' ? 5 : 7;
    final social = 100 - (search + direct + categories + recommendations);

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
          const Text('Traffic Sources', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 35,
                    sections: [
                      PieChartSectionData(color: Colors.green.shade500, value: search.toDouble(), radius: 26, showTitle: false),
                      PieChartSectionData(color: Colors.blue.shade500, value: direct.toDouble(), radius: 26, showTitle: false),
                      PieChartSectionData(color: Colors.amber.shade500, value: categories.toDouble(), radius: 26, showTitle: false),
                      PieChartSectionData(color: Colors.pink.shade400, value: recommendations.toDouble(), radius: 26, showTitle: false),
                      PieChartSectionData(color: Colors.deepPurple.shade400, value: social.toDouble(), radius: 26, showTitle: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendRow(Colors.green.shade500, 'Search', '$search%'),
                    _buildLegendRow(Colors.blue.shade500, 'Direct', '$direct%'),
                    _buildLegendRow(Colors.amber.shade500, 'Categories', '$categories%'),
                    _buildLegendRow(Colors.pink.shade400, 'Recommendations', '$recommendations%'),
                    _buildLegendRow(Colors.deepPurple.shade400, 'Social Media', '$social%'),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
