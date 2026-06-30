import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAFA),
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final userModel = UserModel.fromJson(userSnap.data!.data() as Map<String, dynamic>);
        final storeId = userModel.storeId;

        if (storeId.isEmpty) {
          return const Scaffold(body: Center(child: Text('No store found.')));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').doc(storeId).snapshots(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData || !storeSnap.data!.exists) {
              return const Scaffold(
                backgroundColor: Color(0xFFFAFAFA),
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            final store = StoreModel.fromJson(storeSnap.data!.data() as Map<String, dynamic>);

            final double maxOffset = 180.0;
            final double fraction = (_scrollOffset / maxOffset).clamp(0.0, 1.0);
            
            final Color appBarColor = Colors.white.withOpacity(fraction);
            final Color titleColor = Color.lerp(Colors.white, const Color(0xFF0F172A), fraction)!;
            final double shadowOpacity = (1 - fraction).clamp(0.0, 1.0) * 0.45;

            return Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              extendBodyBehindAppBar: true, 
              appBar: AppBar(
                backgroundColor: appBarColor,
                elevation: fraction > 0.9 ? 1 : 0,
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: Text(
                  'Store',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    shadows: fraction < 0.5 ? [
                      Shadow(color: Colors.black.withOpacity(shadowOpacity), blurRadius: 4, offset: const Offset(0, 1)),
                    ] : null,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.zero, 
                child: Column(
                  children: [
                    _buildHeader(context, store),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildSettingsMenu(context, store),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, StoreModel store) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 260, // Slightly taller to account for status bar area
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(store.banner.isNotEmpty ? store.banner : 'https://images.unsplash.com/photo-1505253758473-96b7015fcd40'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Semi-transparent overlay to ensure text/badges pop
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.3)],
                ),
              ),
            ),
            // White Area for seamless connection
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 50,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            // Logo
            Positioned(
              bottom: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(store.logo.isNotEmpty ? store.logo : 'https://images.unsplash.com/photo-1606787366850-de6330128bfc'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(store.storeName.isNotEmpty ? store.storeName : "Amma's Secrets", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 4),
        Text('${store.city.isNotEmpty ? store.city : 'Hyderabad'}, ${store.state.isNotEmpty ? store.state : 'Telangana'}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        // Instagram-style Metrics Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricColumn(store.totalOrders.toString(), 'Orders'),
                _buildMetricColumn(store.followers > 1000 ? '${(store.followers / 1000).toStringAsFixed(1)}K' : store.followers.toString(), 'Followers'),
                _buildMetricColumn(store.productsCount.toString(), 'Products'),
                _buildMetricColumn('${store.rating}', '${store.totalReviews} Reviews', isRating: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/store/info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    minimumSize: const Size(0, 34),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Edit store', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    minimumSize: const Size(0, 34),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Share store', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String value, String label, {bool isRating = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            if (isRating) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
            ]
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildVacationModeCard(StoreModel store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: store.isActive ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                store.isActive ? Icons.storefront : Icons.beach_access,
                color: store.isActive ? Colors.green[700] : Colors.amber[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vacation Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.isActive ? 'Store is visible and accepting orders' : 'Store is hidden. You are on a break.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: !store.isActive,
              activeColor: Colors.amber[700],
              activeTrackColor: Colors.amber[100],
              inactiveThumbColor: Colors.green[600],
              inactiveTrackColor: Colors.green[100],
              onChanged: (val) async {
                final bool isPausing = val;
                
                if (isPausing) {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Enable Vacation Mode?', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Your store and products will be hidden from customers. You will not receive new orders. Are you sure?'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Enable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm != true) return;
                }
                
                try {
                  await FirebaseFirestore.instance.collection('stores').doc(store.storeId).update({'isActive': !isPausing});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isPausing ? 'Vacation mode enabled.' : 'Your store is back online!'),
                        backgroundColor: isPausing ? Colors.amber[800] : Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to update status. Check your connection.'),
                        backgroundColor: Colors.red[900],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, StoreModel store) {
    return Column(
      children: [
        _buildVacationModeCard(store),
        _buildSettingsCard(
          context: context,
          icon: Icons.link_outlined,
          title: 'Social Links',
          subtitleWidget: Row(
            children: [
              _buildSocialIcon(Icons.camera_alt_outlined, Colors.pink),
              const SizedBox(width: 8),
              _buildSocialIcon(Icons.facebook, Colors.blue),
              const SizedBox(width: 8),
              _buildSocialIcon(Icons.play_circle_fill, Colors.red),
            ],
          ),
          route: '/store/social-links',
        ),
        _buildSettingsCard(
          context: context,
          icon: Icons.business_outlined,
          title: 'Business Details',
          subtitleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Owner Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('Saraswathi Devi', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              const Text('Business Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text("Amma's Secrets Homemade Foods", style: TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              const Text('Business Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('Home Based Business', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 12),
              const Text('Experience', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('5+ Years', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 12),
              const Text('Contact Information', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('hello@ammassecrets.com\n+91 9876543210', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 12),
              const Text('Compliance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('GST: Not Registered\nFSSAI: 21220183001524', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 12),
              const Text('Registered Premises', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('Plot 42, Jubilee Hills Road No. 36...', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
            ],
          ),
          route: '/store/business-details',
        ),
        _buildSettingsCard(
          context: context,
          icon: Icons.account_balance_outlined,
          title: 'Banking & Payouts',
          subtitleWidget: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Holder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              SizedBox(height: 2),
              Text("Saraswathi Devi", style: TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              Text('Bank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              SizedBox(height: 2),
              Text('HDFC Bank', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              SizedBox(height: 12),
              Text('Account Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              SizedBox(height: 2),
              Text('•••••• 1234', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              SizedBox(height: 12),
              Text('IFSC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              SizedBox(height: 2),
              Text('HDFC0001234', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
            ],
          ),
          route: '/store/banking',
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget subtitleWidget,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  subtitleWidget,
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => context.push(route),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)));
        final tp = TextPainter(text: span, maxLines: 2, textDirection: TextDirection.ltr);
        tp.layout(maxWidth: constraints.maxWidth);
        
        if (tp.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                maxLines: _isExpanded ? null : 2,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded ? 'View Less' : 'View More',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          );
        } else {
          return Text(widget.text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)));
        }
      },
    );
  }
}
