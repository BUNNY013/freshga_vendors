import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userModel?.userId;
    
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            final isVerified = userData['isVerified'] == true || 
                               userData['isVerified']?.toString().toLowerCase() == 'true';
            if (isVerified) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/dashboard');
              });
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('supplierApplications')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Scaffold(body: Center(child: Text("Application not found.")));
            }

            final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            final adminRemarks = data['adminRemarks'] as String? ?? '';
            final taxType = data['taxRegistrationType'] as String? ?? '';
            final fssaiStatus = data['fssaiStatus'] as String? ?? '';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (status == 'approved') {
                context.go('/dashboard');
              } else if (status == 'rejected_permanent') {
                context.go('/rejected');
              }
            });

            final needsAgentHelp = (taxType == 'NeedsHelp' || fssaiStatus == 'NeedsHelp');
            final isChangesRequired = (status == 'changes_required');

            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
              body: RefreshIndicator(
                onRefresh: () async {
                  await context.read<AuthProvider>().refreshApplicationStatus();
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Gradient Header
                      _buildPremiumHeader(context, isChangesRequired, adminRemarks, needsAgentHelp, data),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why Partner with FreshGa?', 
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              )
                            ),
                            const SizedBox(height: 16),
                            _buildPremiumBenefitCard(
                              icon: Icons.percent_rounded,
                              title: 'Zero Commission',
                              description: 'Keep 100% of your earnings for the first 30 days.',
                              gradientColors: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            const SizedBox(height: 16),
                            _buildPremiumBenefitCard(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Secure Weekly Payouts',
                              description: 'Get paid every week securely and directly to your bank account.',
                              gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            const SizedBox(height: 16),
                            _buildPremiumBenefitCard(
                              icon: Icons.delivery_dining_rounded,
                              title: 'Vendor Self Delivery',
                              description: 'Deliver orders yourself or tap into our reliable delivery network.',
                              gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                            ),
                            
                            const SizedBox(height: 32),
                            Text(
                              'Powerful App Features', 
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildFeatureRow(Icons.inventory_2_rounded, 'Manage Products', 'Easily add, update, and manage your inventory.'),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(color: Color(0xFFEEEEEE)),
                                  ),
                                  _buildFeatureRow(Icons.receipt_long_rounded, 'Real-time Orders', 'Get notified instantly and process orders easily.'),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(color: Color(0xFFEEEEEE)),
                                  ),
                                  _buildFeatureRow(Icons.storefront_rounded, 'Reach More Customers', 'Connect directly with thousands of hungry customers.'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomContactBar(context),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isChangesRequired, String adminRemarks, bool needsAgentHelp, Map<String, dynamic> data) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Gradient Curve
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 60, bottom: 80, left: 24, right: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isChangesRequired 
                ? [Colors.red.shade400, Colors.red.shade700]
                : [AppColors.primary, const Color(0xFF2E7D32)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () async {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Animated Icon Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  isChangesRequired ? Icons.edit_document : Icons.hourglass_top_rounded,
                  color: isChangesRequired ? Colors.red : AppColors.primary,
                  size: 56,
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                isChangesRequired ? 'Changes Required' : 'Application Submitted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isChangesRequired 
                    ? 'The Admin has reviewed your application and requested some updates.'
                    : 'Your FreshGa store verification is currently under review.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Extra space to accommodate the overlapping cards
              SizedBox(height: (isChangesRequired || needsAgentHelp) ? 40 : 20),
            ],
          ),
        ),

        // Overlapping Alert Cards (Agent Help or Changes Required)
        if (isChangesRequired || needsAgentHelp)
          Positioned(
            bottom: -30,
            left: 24,
            right: 24,
            child: isChangesRequired 
              ? _buildAlertCard(
                  icon: Icons.info_outline,
                  iconColor: Colors.red,
                  title: 'Admin Remarks',
                  message: adminRemarks,
                  bgColor: Colors.white,
                )
              : _buildAlertCard(
                  icon: Icons.support_agent_rounded,
                  iconColor: Colors.orange.shade700,
                  title: 'Registration Help',
                  message: 'Our agent will contact you shortly to help with FSSAI/GST registration.',
                  bgColor: Colors.white,
                ),
          ),
          
        if (isChangesRequired)
          Positioned(
            bottom: -90,
            left: 24,
            right: 24,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  context.read<OnboardingProvider>().hydrateFromFirestore(data);
                  context.go('/onboarding/step1');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertCard({required IconData icon, required Color iconColor, required String title, required String message, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 15)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefitCard({required IconData icon, required String title, required String description, required List<Color> gradientColors}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: gradientColors.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Color(0xFF757575), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomContactBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Need help with your application?',
              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _launchURL('tel:+919876543210'),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call Us', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _launchURL('mailto:support@freshga.com'),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email Us', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
