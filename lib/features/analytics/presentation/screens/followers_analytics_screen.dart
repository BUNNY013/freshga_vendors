import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../store/domain/models/store_model.dart';
import '../widgets/premium_line_chart_card.dart';

class FollowersAnalyticsScreen extends StatefulWidget {
  const FollowersAnalyticsScreen({super.key});

  @override
  State<FollowersAnalyticsScreen> createState() => _FollowersAnalyticsScreenState();
}

class _FollowersAnalyticsScreenState extends State<FollowersAnalyticsScreen> {

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
            final int totalFollowers = store.followers;

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
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Total Followers', '$totalFollowers', 'No trend', Colors.black87)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatBox('New Followers', '0', 'No trend', Colors.black87)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatBox('Unfollowed', '0', 'No trend', Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    PremiumLineChartCard(
                      title: 'Follower Growth',
                      primaryMetricLabel: 'Followers',
                      chartColor: Colors.green.shade600,
                      selectedFilter: '30D',
                      xLabels: const [],
                      dataSpots: const [],
                      onFilterChanged: (newFilter) {},
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
        );
      }
    );
  }

  Widget _buildStatBox(String title, String value, String trend, Color color) {
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
              Icon(Icons.horizontal_rule, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Text(
                trend, 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)
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
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.location_on_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text("No location data available", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          )
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
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text("No engagement data available", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
