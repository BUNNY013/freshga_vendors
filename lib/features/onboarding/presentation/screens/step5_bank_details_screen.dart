import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../widgets/primary_button.dart';

class Step5BankDetailsScreen extends StatefulWidget {
  const Step5BankDetailsScreen({super.key});

  @override
  State<Step5BankDetailsScreen> createState() => _Step5BankDetailsScreenState();
}

class _Step5BankDetailsScreenState extends State<Step5BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      context.read<OnboardingProvider>().saveDraft();
      context.push('/onboarding/step6');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 5),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your earnings will be securely transferred here 💸',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      PremiumTextField(
                        label: 'Account Holder Name',
                        controller: provider.accountNameController,
                        hintText: 'As per bank records',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      PremiumTextField(
                        label: 'Account Number',
                        controller: provider.accountNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter account number',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      PremiumTextField(
                        label: 'Confirm Account Number',
                        controller: provider.confirmAccountNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Re-enter account number',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value != provider.accountNumberController.text)
                            return 'Account numbers do not match';
                          return null;
                        },
                      ),
                      PremiumTextField(
                        label: 'IFSC Code',
                        controller: provider.ifscController,
                        hintText: '11-character IFSC code',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 11) return 'Invalid IFSC length';
                          return null;
                        },
                      ),
                      PremiumTextField(
                        label: 'Bank Name',
                        controller: provider.bankNameController,
                        hintText: 'E.g., HDFC Bank',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      PremiumTextField(
                        label: 'UPI ID',
                        controller: provider.upiController,
                        hintText: 'E.g., yourname@bank (optional)',
                        isRequired: false,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: PrimaryButton(
                  text: 'Review & Submit',
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
