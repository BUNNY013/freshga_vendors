import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/premium_line_chart_card.dart';

class FollowersAnalyticsScreen extends StatefulWidget {
  const FollowersAnalyticsScreen({super.key});

  @override
  State<FollowersAnalyticsScreen> createState() => _FollowersAnalyticsScreenState();
}

class _FollowersAnalyticsScreenState extends State<FollowersAnalyticsScreen> {
  String _chartFilter = '30D';

  @override
  Widget build(BuildContext context) {
    // Dynamic Mock Data Injection based on selected filter
    final int totalFollowers = _chartFilter == '7D' ? 124 : _chartFilter == '30D' ? 1248 : _chartFilter == '90D' ? 4850 : 8900;
    final int newFollowers = _chartFilter == '7D' ? 24 : _chartFilter == '30D' ? 86 : _chartFilter == '90D' ? 450 : 8900;
    final int unfollowed = _chartFilter == '7D' ? 2 : _chartFilter == '30D' ? 12 : _chartFilter == '90D' ? 56 : 145;
    
    final List<String> labels = _chartFilter == '7D' ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'] 
                              : _chartFilter == '30D' ? ['W1', 'W2', 'W3', 'W4'] 
                              : _chartFilter == '90D' ? ['M1', 'M2', 'M3'] 
                              : ['2023', '2024'];
                              
    final List<FlSpot> spots = List.generate(labels.length, (index) {
       final base = totalFollowers * 0.4;
       final randomGrowth = (index + 1) * (totalFollowers / (labels.length + 1));
       return FlSpot(index.toDouble(), base + randomGrowth);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Followers Analytics', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
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
                Expanded(child: _buildStatBox('Total Followers', '$totalFollowers', '▲ 12.7%', Colors.black87)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox('New Followers', '$newFollowers', '▲ 18.3%', Colors.black87)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox('Unfollowed', '$unfollowed', '↓ 3.2%', Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),
            
            PremiumLineChartCard(
              title: 'Follower Growth',
              primaryMetricLabel: 'Followers',
              chartColor: Colors.green.shade600,
              selectedFilter: _chartFilter,
              xLabels: labels,
              dataSpots: spots,
              onFilterChanged: (newFilter) {
                setState(() => _chartFilter = newFilter);
              },
            ),
            const SizedBox(height: 24),
            
            _buildTopLocationsCard(),
            const SizedBox(height: 24),
            
            _buildTopEngagedFollowers(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? Colors.green : Colors.red, size: 12),
              const SizedBox(width: 4),
              Text(
                trend.replaceAll('▲ ', '').replaceAll('↓ ', ''), 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isPositive ? Colors.green : Colors.red)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTopLocationsCard() {
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
          const Text('Followers by Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          if (_chartFilter == '7D') ...[
            _buildCityRow('01', 'Bangalore', '42%'),
            _buildCityRow('02', 'Hyderabad', '21%'),
            _buildCityRow('03', 'Chennai', '11%'),
            _buildCityRow('04', 'Vijayawada', '8%'),
            _buildCityRow('05', 'Others', '18%', isLast: true),
          ] else if (_chartFilter == '90D') ...[
            _buildCityRow('01', 'Vijayawada', '38%'),
            _buildCityRow('02', 'Visakhapatnam', '22%'),
            _buildCityRow('03', 'Hyderabad', '18%'),
            _buildCityRow('04', 'Bangalore', '12%'),
            _buildCityRow('05', 'Others', '10%', isLast: true),
          ] else ...[
            _buildCityRow('01', 'Hyderabad', '32%'),
            _buildCityRow('02', 'Vijayawada', '18%'),
            _buildCityRow('03', 'Bangalore', '12%'),
            _buildCityRow('04', 'Chennai', '10%'),
            _buildCityRow('05', 'Visakhapatnam', '6%'),
            _buildCityRow('06', 'Others', '22%', isLast: true),
          ],
        ],
      ),
    );
  }

  Widget _buildCityRow(String rank, String city, String data, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(rank, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(city, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          Text(data, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
        ],
      ),
    );
  }

  Widget _buildTopEngagedFollowers() {
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
          const Text('Top Engaged Followers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          if (_chartFilter == '7D') ...[
            _buildFollowerRow('Kiran Mai', '4 orders'),
            _buildFollowerRow('Suresh V', '3 orders'),
            _buildFollowerRow('Anitha Rao', '2 orders', isLast: true),
          ] else if (_chartFilter == '90D') ...[
            _buildFollowerRow('Ramesh Kumar', '210 orders'),
            _buildFollowerRow('Lakshmi Priya', '180 orders'),
            _buildFollowerRow('Divya Sri', '145 orders', isLast: true),
          ] else ...[
            _buildFollowerRow('Lakshmi Priya', '142 orders'),
            _buildFollowerRow('Ramesh Kumar', '96 orders'),
            _buildFollowerRow('Anitha Rao', '76 orders', isLast: true),
          ]
        ],
      ),
    );
  }

  Widget _buildFollowerRow(String name, String data, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            radius: 20,
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(data, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            )
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
