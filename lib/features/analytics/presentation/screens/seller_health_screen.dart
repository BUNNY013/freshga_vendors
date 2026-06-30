import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SellerHealthScreen extends StatefulWidget {
  const SellerHealthScreen({super.key});

  @override
  State<SellerHealthScreen> createState() => _SellerHealthScreenState();
}

class _SellerHealthScreenState extends State<SellerHealthScreen> {
  String _chartFilter = '30D';

  @override
  Widget build(BuildContext context) {
    // Dynamic Mock Data Injection based on selected filter
    final int healthScore = _chartFilter == '7D' ? 92 : _chartFilter == '30D' ? 96 : _chartFilter == '90D' ? 94 : 95;
    
    final int accRate = _chartFilter == '7D' ? 95 : 98;
    final int dispatch = _chartFilter == '7D' ? 94 : 97;
    final String cancel = _chartFilter == '7D' ? '2.4%' : '1.2%';
    final int response = _chartFilter == '7D' ? 96 : 99;
    final String returnRate = _chartFilter == '7D' ? '1.5%' : '0.5%';
    final int completion = _chartFilter == '7D' ? 95 : 99;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seller Health', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
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
                Expanded(flex: 4, child: _buildHealthScoreCard(healthScore)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildHealthMetric('Order Acceptance Rate', '$accRate%'),
                        const SizedBox(height: 12),
                        _buildHealthMetric('On-time Dispatch', '$dispatch%'),
                        const SizedBox(height: 12),
                        _buildHealthMetric('Cancellation Rate', cancel),
                        const SizedBox(height: 12),
                        _buildHealthMetric('Response Rate', '$response%'),
                        const SizedBox(height: 12),
                        _buildHealthMetric('Return Rate', returnRate),
                        const SizedBox(height: 12),
                        _buildHealthMetric('Completion Rate', '$completion%'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildFeedbackSection(
              'What you\'re doing great', 
              Icons.check_circle, 
              Colors.green.shade700, 
              [
                'Orders are accepted quickly',
                'On-time dispatch is excellent',
                'Low cancellation rate',
              ]
            ),
            const SizedBox(height: 24),
            
            _buildFeedbackSection(
              'Areas to improve', 
              Icons.warning_amber_rounded, 
              Colors.amber.shade700, 
              _chartFilter == '7D' ? [
                'Increase response rate to customer queries',
                'Reduce return rate on fragile items',
              ] : [
                'Add more products to increase visibility',
                'Improve product photos for better conversion',
              ]
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(int score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text('$score%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          Text(score >= 95 ? 'Excellent' : 'Good', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
          const SizedBox(height: 12),
          Text(
            score >= 95 
              ? "Great job! You're performing well across all key areas." 
              : "Doing well, but a few areas need attention.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.4),
          )
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value) {
    return Row(
      children: [
        Icon(Icons.shield_outlined, color: Colors.green.shade600, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.w800))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
      ],
    );
  }

  Widget _buildFeedbackSection(String title, IconData icon, Color color, List<String> points) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          ...points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
