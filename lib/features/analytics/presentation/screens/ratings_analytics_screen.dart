import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../store/domain/models/store_model.dart';

class RatingsAnalyticsScreen extends StatefulWidget {
  const RatingsAnalyticsScreen({super.key});

  @override
  State<RatingsAnalyticsScreen> createState() => _RatingsAnalyticsScreenState();
}

class _RatingsAnalyticsScreenState extends State<RatingsAnalyticsScreen> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
        
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Scaffold(body: Center(child: Text('User error')));

        final storeId = UserModel.fromJson(userData).storeId;
        if (storeId.isEmpty) return const Scaffold(body: Center(child: Text('Store not setup')));

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').doc(storeId).snapshots(),
          builder: (context, storeSnap) {
            if (storeSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
            }

            final storeData = storeSnap.data?.data() as Map<String, dynamic>?;
            if (storeData == null) return const Scaffold(body: Center(child: Text('Store not found')));

            final store = StoreModel.fromJson(storeData);

            // Since real customer reviews feature is not yet built, we default these distribution to 0
            // but show the actual Store rating.
            final avgRating = store.rating;
            final totalReviews = store.totalReviews;
            
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
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Average Rating', avgRating.toStringAsFixed(1), 'No trends yet', '')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatBox('Total Reviews', totalReviews.toString(), 'No trends yet', '')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildRatingDistribution(0, 0, 0, 0, 0, 0),
                    const SizedBox(height: 24),
                    
                    _buildEmptyReviews(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildStatBox(String title, String value, String trend, String subtext) {
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
              Icon(Icons.horizontal_rule, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$trend $subtext', 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
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
          _buildDistRow('5 Stars', total == 0 ? 0 : d5 / total, Colors.green.shade800, '$d5 (${total == 0 ? 0 : ((d5/total)*100).toInt()}%)'),
          _buildDistRow('4 Stars', total == 0 ? 0 : d4 / total, Colors.green.shade600, '$d4 (${total == 0 ? 0 : ((d4/total)*100).toInt()}%)'),
          _buildDistRow('3 Stars', total == 0 ? 0 : d3 / total, Colors.amber.shade500, '$d3 (${total == 0 ? 0 : ((d3/total)*100).toInt()}%)'),
          _buildDistRow('2 Stars', total == 0 ? 0 : d2 / total, Colors.deepOrange.shade400, '$d2 (${total == 0 ? 0 : ((d2/total)*100).toInt()}%)'),
          _buildDistRow('1 Star', total == 0 ? 0 : d1 / total, Colors.red.shade600, '$d1 (${total == 0 ? 0 : ((d1/total)*100).toInt()}%)'),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.shade100,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 55,
            child: Text(countStr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.right),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
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
              Text('See All', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text("No reviews yet", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
