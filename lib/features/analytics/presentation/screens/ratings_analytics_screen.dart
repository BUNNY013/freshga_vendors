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

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reviews').where('storeId', isEqualTo: storeId).orderBy('createdAt', descending: true).limit(10).snapshots(),
              builder: (context, reviewsSnap) {
                final docs = reviewsSnap.data?.docs ?? [];
                
                int totalReviews = store.totalReviews; // Keep the real counter if docs are paginated/limited
                double avgRating = store.rating;
                
                // We'll calculate distribution from the recent 10 if totalReviews > 0
                // Or just use the fetched ones. Actually let's query all if we want distribution!
                // We'll just stream all reviews for the store to get the real distribution.
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('reviews').where('storeId', isEqualTo: storeId).snapshots(),
                  builder: (context, allReviewsSnap) {
                    final allDocs = allReviewsSnap.data?.docs ?? [];
                    int total = allDocs.length;
                    double calcAvg = 0;
                    int d5=0, d4=0, d3=0, d2=0, d1=0;

                    if (total > 0) {
                      double sum = 0;
                      for (var doc in allDocs) {
                        final r = ((doc.data() as Map<String,dynamic>)['rating'] as num?)?.toDouble() ?? 0;
                        sum += r;
                        if (r >= 4.5) d5++;
                        else if (r >= 3.5) d4++;
                        else if (r >= 2.5) d3++;
                        else if (r >= 1.5) d2++;
                        else d1++;
                      }
                      calcAvg = sum / total;
                    } else {
                      calcAvg = store.rating;
                      total = store.totalReviews;
                    }

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
                                Expanded(child: _buildStatBox('Average Rating', total == 0 ? 'New' : calcAvg.toStringAsFixed(1), 'Realtime', '')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatBox('Total Reviews', total.toString(), 'Realtime', '')),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            _buildRatingDistribution(d5, d4, d3, d2, d1, total),
                            const SizedBox(height: 24),
                            
                            _buildRecentReviews(allDocs),
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

  Widget _buildRecentReviews(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
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
            const Text('Recent Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

    final recent = docs.take(5).toList();

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
          const Text('Recent Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 24),
          ...recent.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
            final text = (data['feedback'] ?? data['reviewText'] ?? '') as String;
            final customerName = data['customerName'] as String? ?? 'Customer';
            final productName = data['productName'] as String? ?? 'Store Experience';
            final orderId = data['orderId'] as String?;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          customerName, 
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    orderId != null ? '$productName (Order: #$orderId)' : productName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"$text"', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
