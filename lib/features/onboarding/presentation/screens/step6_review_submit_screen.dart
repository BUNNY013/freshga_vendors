import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/primary_button.dart';

class Step6ReviewSubmitScreen extends StatefulWidget {
  const Step6ReviewSubmitScreen({super.key});

  @override
  State<Step6ReviewSubmitScreen> createState() =>
      _Step6ReviewSubmitScreenState();
}

class _Step6ReviewSubmitScreenState extends State<Step6ReviewSubmitScreen> {
  bool _confirmed = false;

  void _submit() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the information is accurate.'),
        ),
      );
      return;
    }

    final provider = context.read<OnboardingProvider>();
    final success = await provider.submitApplication();

    if (success && mounted) {
      context.go('/pending');
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  Widget _buildSummarySection(
    String title,
    Map<String, String> data,
    VoidCallback onEdit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text(
                  'Edit',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(),
          ...data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review your details ✨',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),

                    _buildSummarySection(
                      'Basic Details',
                      {
                        'Full Name': provider.fullNameController.text,
                        'Business Name': provider.businessNameController.text,
                        'Phone': provider.phoneController.text,
                        'Email': provider.emailController.text,
                      },
                      () => Navigator.popUntil(
                        context,
                        (route) =>
                            route.settings.name == '/onboarding/step1' ||
                            route.isFirst,
                      ),
                    ),

                    _buildSummarySection(
                      'Business Info',
                      {
                        'Categories': provider.selectedFoodCategories.join(
                          ', ',
                        ),
                        'Dispatch': provider.selectedDispatchTime ?? '',
                        'Experience': provider.experienceController.text,
                      },
                      () => context
                          .pop(), // Adjust logic for deep edit navigation if needed
                    ),

                    _buildSummarySection('Address Details', {
                      'City': provider.cityController.text,
                      'State': provider.stateController.text,
                      'Pincode': provider.pincodeController.text,
                    }, () => context.pop()),

                    _buildSummarySection('Legal & Bank', {
                      'FSSAI Number': provider.fssaiNumberController.text,
                      'PAN Number': provider.panNumberController.text,
                      'Bank Name': provider.bankNameController.text,
                      'A/C Number': provider.accountNumberController.text,
                    }, () => context.pop()),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _confirmed,
                          onChanged: (val) =>
                              setState(() => _confirmed = val ?? false),
                          activeColor: AppColors.primary,
                        ),
                        const Expanded(
                          child: Text(
                            'I confirm that all information provided is accurate.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: PrimaryButton(
                text: 'Submit for Verification',
                onPressed: _submit,
                isLoading: provider.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
