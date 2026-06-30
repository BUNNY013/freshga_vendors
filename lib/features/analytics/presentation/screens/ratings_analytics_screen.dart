import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RatingsAnalyticsScreen extends StatefulWidget {
  const RatingsAnalyticsScreen({super.key});

  @override
  State<RatingsAnalyticsScreen> createState() => _RatingsAnalyticsScreenState();
}

class _RatingsAnalyticsScreenState extends State<RatingsAnalyticsScreen> {
  String _activeFilter = '30D';

  @override
  Widget build(BuildContext context) {
    // Dynamic Mock Data Injection based on filter
    final avgRating = _activeFilter == '30D' ? 4.8 : _activeFilter == '90D' ? 4.6 : 4.7;
    final totalReviews = _activeFilter == '30D' ? 326 : _activeFilter == '90D' ? 842 : 1240;
    final trendAvg = _activeFilter == '30D' ? '▲ 0.2' : _activeFilter == '90D' ? '▲ 0.1' : '▲ 0.3';
    final trendTotal = _activeFilter == '30D' ? '▲ 14.2%' : _activeFilter == '90D' ? '▲ 22.4%' : '▲ 45.1%';
    
    // Distribution metrics (Mock)
    final d5 = _activeFilter == '30D' ? 234 : 612;
    final d4 = _activeFilter == '30D' ? 68 : 180;
    final d3 = _activeFilter == '30D' ? 16 : 32;
    final d2 = _activeFilter == '30D' ? 5 : 12;
    final d1 = _activeFilter == '30D' ? 3 : 6;
    
    final t = d5 + d4 + d3 + d2 + d1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Store Rating & Reviews', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
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
                  Expanded(child: Text("Displaying dynamic mock ratings for UI testing.", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13))),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildStatBox('Average Rating', avgRating.toString(), trendAvg, 'from last 30 days')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox('Total Reviews', totalReviews.toString(), trendTotal, '')),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildRatingDistribution(d5, d4, d3, d2, d1, t),
            const SizedBox(height: 24),
            
            _buildRecentReviews(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  Widget _buildStatBox(String title, String value, String trend, String subtext) {
    final isPositive = trend.contains('▲');
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              if (title.contains('Rating')) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, color: Colors.amber, size: 24),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? Colors.green : Colors.red, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${trend.replaceAll('▲ ', '').replaceAll('↓ ', '')} $subtext', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isPositive ? Colors.green : Colors.red),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(int d5, int d4, int d3, int d2, int d1, int total) {
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
          const Text('Rating Distribution', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 20),
          _buildDistRow('5 Stars', d5 / total, Colors.green.shade800, '$d5 (${((d5/total)*100).toInt()}%)'),
          _buildDistRow('4 Stars', d4 / total, Colors.green.shade600, '$d4 (${((d4/total)*100).toInt()}%)'),
          _buildDistRow('3 Stars', d3 / total, Colors.amber.shade500, '$d3 (${((d3/total)*100).toInt()}%)'),
          _buildDistRow('2 Stars', d2 / total, Colors.deepOrange.shade400, '$d2 (${((d2/total)*100).toInt()}%)'),
          _buildDistRow('1 Star', d1 / total, Colors.red.shade600, '$d1 (${((d1/total)*100).toInt()}%)'),
        ],
      ),
    );
  }

  Widget _buildDistRow(String label, double percent, Color color, String countStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 55, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textPrimary))),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 65, child: Text(countStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildRecentReviews() {
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
              const Text('Recent Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('View all', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 24),
          if (_activeFilter == '30D') ...[
            _buildReviewRow('Lakshmi Priya', '5', 'Very tasty and homemade feel. Packaging was also very good. Will order again!', '2 hours ago'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.background)),
            _buildReviewRow('Ramesh Kumar', '4', 'Good quality pickle. Spicy and fresh.', '1 day ago'),
          ] else ...[
            _buildReviewRow('Anita Rao', '5', 'Excellent packaging and fast delivery. The taste is incredibly authentic.', '4 days ago'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.background)),
            _buildReviewRow('Suresh V', '3', 'It was a bit too salty for my taste, but the quality of ingredients seemed good.', '1 week ago'),
          ]
        ],
      ),
    );
  }

  Widget _buildReviewRow(String name, String rating, String comment, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey, size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              children: [
                Text(rating, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green.shade700)),
                const SizedBox(width: 4),
                Icon(Icons.star, color: Colors.green.shade700, size: 16),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(comment, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
