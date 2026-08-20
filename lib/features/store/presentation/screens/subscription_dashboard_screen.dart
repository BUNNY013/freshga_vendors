import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String _processingPlan = ''; // 'monthly' or 'yearly'
  Map<String, dynamic>? _globalSettings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadGlobalSettings();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadGlobalSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('global_settings').doc('settings').get();
      if (doc.exists && mounted) {
        setState(() {
          _globalSettings = doc.data();
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  void _startPayment(String plan) {
    setState(() {
      _isProcessing = true;
      _processingPlan = plan;
    });
    
    int monthlyPrice = _globalSettings?['subscription_monthly_price'] ?? 299;
    int yearlyPrice = _globalSettings?['subscription_yearly_price'] ?? 2499;
    int amount = plan == 'monthly' ? monthlyPrice * 100 : yearlyPrice * 100; // in paise
    
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    
    var options = {
      'key': 'rzp_test_TOo0mUDrME9tJp', // TODO: Use real key for prod
      'amount': amount,
      'name': 'FreshGa Premium',
      'description': 'Store Subscription - ${plan == 'monthly' ? '1 Month' : '1 Year'}',
      'timeout': 120,
      'prefill': {
        'contact': phone,
      },
      'theme': {
        'color': '#16A34A' // Green
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching payment: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final subProvider = context.read<SubscriptionProvider>();
      final currentSub = subProvider.currentSubscription;
      
      if (currentSub == null) throw Exception("No subscription found");

      // Calculate new expiry
      DateTime baseDate = DateTime.now();
      
      // If they are currently active (or in grace period), extend from their current expiry
      if (currentSub.isPaidActive || currentSub.isInGracePeriod) {
        baseDate = currentSub.currentPeriodEnd!;
      } else if (currentSub.isTrialActive) {
        baseDate = currentSub.trialEndsAt;
      }
      
      final daysToAdd = _processingPlan == 'monthly' ? 30 : 365;
      final newExpiry = baseDate.add(Duration(days: daysToAdd));

      await FirebaseFirestore.instance
          .collection('store_subscriptions')
          .doc(currentSub.storeId)
          .update({
        'status': 'active',
        'currentPeriodEnd': newExpiry.toIso8601String(),
      });

      await subProvider.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Subscription Renewed Successfully! 🎉"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update database: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Very light grey / off-white
      appBar: AppBar(
        title: const Text("FreshGa Premium", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || _isLoadingSettings) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          
          final sub = provider.currentSubscription;
          if (sub == null) {
            return const Center(child: Text("Error loading subscription data", style: TextStyle(color: Colors.black54)));
          }

          int yearlyPrice = _globalSettings?['subscription_yearly_price'] ?? 2499;
          int yearlyOriginal = _globalSettings?['subscription_yearly_original_price'] ?? 5988;
          int monthlyPrice = _globalSettings?['subscription_monthly_price'] ?? 299;
          int monthlyOriginal = _globalSettings?['subscription_monthly_original_price'] ?? 499;
          
          int yearlySavings = yearlyOriginal - yearlyPrice;
          
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatusCard(sub),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPricingCard(
                    id: 'yearly',
                    title: 'Pro Annual',
                    price: '₹$yearlyPrice',
                    originalPrice: yearlyOriginal > yearlyPrice ? '₹$yearlyOriginal' : null,
                    period: '/ year',
                    subtitle: yearlySavings > 0 ? 'Save ₹$yearlySavings every year' : 'Best value for long term',
                    features: [
                      'Unlimited Order Processing',
                      'Priority Store Listing',
                      'Analytics & Insights',
                      'No commission on sales'
                    ],
                    isPopular: true,
                    isPaidActive: sub.isPaidActive,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)], // Green gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPricingCard(
                    id: 'monthly',
                    title: 'Pro Monthly',
                    price: '₹$monthlyPrice',
                    originalPrice: monthlyOriginal > monthlyPrice ? '₹$monthlyOriginal' : null,
                    period: '/ month',
                    subtitle: 'Flexible pay-as-you-go',
                    features: [
                      'Unlimited Order Processing',
                      'Standard Store Listing',
                      'Analytics & Insights',
                      'No commission on sales'
                    ],
                    isPopular: false,
                    isPaidActive: sub.isPaidActive,
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                _buildSocialProof(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildStatusCard(var sub) {
    Color badgeColor = Colors.grey;
    String title = "Unknown";
    String dateStr = "";
    Color bgColor = Colors.white;

    if (sub.isTrialActive) {
      badgeColor = Colors.blue;
      bgColor = Colors.blue.shade50;
      title = "Free Trial Active";
      dateStr = "Ends ${DateFormat('MMM dd, yyyy').format(sub.trialEndsAt)}";
    } else if (sub.isPaidActive) {
      badgeColor = Colors.green;
      bgColor = Colors.green.shade50;
      title = "Pro Subscription Active";
      dateStr = "Renews ${DateFormat('MMM dd, yyyy').format(sub.currentPeriodEnd!)}";
    } else if (sub.isInGracePeriod) {
      badgeColor = Colors.orange.shade800;
      bgColor = Colors.orange.shade50;
      title = "Payment Overdue (Grace Period)";
      dateStr = "Expires ${DateFormat('MMM dd, yyyy').format(sub.currentPeriodEnd!.add(const Duration(days: 3)))}";
    } else if (sub.isCompletelyExpired) {
      badgeColor = Colors.red;
      bgColor = Colors.red.shade50;
      title = "Store Offline";
      dateStr = "Subscription expired. Renew to accept orders.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: badgeColor)),
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(color: Colors.black87, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String id,
    required String title,
    required String price,
    String? originalPrice,
    required String period,
    required String subtitle,
    required List<String> features,
    required bool isPopular,
    required Gradient gradient,
    required bool isPaidActive,
  }) {
    final isProcessingThis = _isProcessing && _processingPlan == id;
    
    final textColorPrimary = isPopular ? Colors.white : Colors.black87;
    final textColorSecondary = isPopular ? Colors.white.withOpacity(0.9) : Colors.grey.shade700;
    final textColorMuted = isPopular ? Colors.white.withOpacity(0.7) : Colors.grey.shade500;
    final checkColor = isPopular ? Colors.white : Colors.green.shade600;
    final subtitleColor = isPopular ? const Color(0xFF86EFAC) : Colors.green.shade600; // Light green vs regular green
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: isPopular ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          else
             BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B), // Amber for contrast
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  "MOST POPULAR",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColorSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: TextStyle(color: textColorPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    if (originalPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                        child: Text(originalPrice, style: TextStyle(color: textColorMuted, fontSize: 18, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                      child: Text(period, style: TextStyle(color: textColorMuted, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFF59E0B)], // Gold to Amber
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.black87, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  )
                else
                  Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                ...features.map((feat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: checkColor, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(feat, style: TextStyle(color: textColorSecondary, fontSize: 14))),
                    ],
                  ),
                )),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _startPayment(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.white : Colors.green.shade600,
                      foregroundColor: isPopular ? Colors.green.shade700 : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide.none,
                    ),
                    child: isProcessingThis
                        ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: isPopular ? Colors.green.shade700 : Colors.white, strokeWidth: 2))
                        : Text(
                            isPaidActive ? "Extend $title" : "Choose $title",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProof() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          "Secure payments via Razorpay",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
