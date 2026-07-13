import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Application not found."));
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

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().refreshApplicationStatus();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isChangesRequired ? Colors.red.shade50 : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isChangesRequired ? Icons.edit_document : Icons.hourglass_top_rounded,
                          color: isChangesRequired ? Colors.red : AppColors.primary,
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        isChangesRequired ? '⚠️ Changes Required' : '🎉 Application Submitted',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isChangesRequired 
                            ? 'The Admin has reviewed your application and requested some updates.'
                            : 'Your FreshGa store verification is under review.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      if (isChangesRequired) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Admin Remarks:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 8),
                              Text(adminRemarks, style: TextStyle(color: Colors.red.shade900)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              context.read<OnboardingProvider>().hydrateFromFirestore(data);
                              context.go('/onboarding/step1');
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text('Edit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ] else ...[
                        if (needsAgentHelp) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.support_agent_rounded, color: Colors.orange, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Our agent will contact you shortly to help you register for your missing FSSAI or GST Enrolment ID.',
                                    style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '⏳ Verification usually completes within 24 hours.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 48),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.headset_mic_rounded),
                          label: const Text('Contact Support'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }
}
