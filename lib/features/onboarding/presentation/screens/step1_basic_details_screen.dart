import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class Step1BasicDetailsScreen extends StatefulWidget {
  const Step1BasicDetailsScreen({super.key});

  @override
  State<Step1BasicDetailsScreen> createState() =>
      _Step1BasicDetailsScreenState();
}

class _Step1BasicDetailsScreenState extends State<Step1BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      context.read<OnboardingProvider>().saveDraft();
      context.push('/onboarding/step2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 1),
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
                        'Let’s start with your business basics ✨',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Full Name',
                        controller: provider.fullNameController,
                        hintText: 'Enter your full name',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Business Name',
                        controller: provider.businessNameController,
                        hintText: 'Enter your business name',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Phone Number',
                        controller: provider.phoneController,
                        keyboardType: TextInputType.phone,
                        readOnly: true, // Phone is prefilled and read-only
                        hintText: '+91 XXXXX XXXXX',
                      ),
                      CustomTextField(
                        label: 'Email Address',
                        controller: provider.emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter your email address',
                        isRequired: false,
                      ),
                      CustomTextField(
                        label: 'Instagram Link',
                        controller: provider.instagramController,
                        keyboardType: TextInputType.url,
                        hintText: 'https://instagram.com/yourbusiness',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: PrimaryButton(text: 'Continue', onPressed: _nextStep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
