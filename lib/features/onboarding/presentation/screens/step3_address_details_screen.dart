import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class Step3AddressDetailsScreen extends StatefulWidget {
  const Step3AddressDetailsScreen({super.key});

  @override
  State<Step3AddressDetailsScreen> createState() =>
      _Step3AddressDetailsScreenState();
}

class _Step3AddressDetailsScreenState extends State<Step3AddressDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      context.read<OnboardingProvider>().saveDraft();
      context.push('/onboarding/step4');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 3),
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
                        'Where will you be cooking from?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Business Address',
                        controller: provider.businessAddressController,
                        hintText: 'House No, Street, Landmark',
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Pickup Address',
                        controller: provider.pickupAddressController,
                        hintText: 'Same as Business Address or different?',
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'City',
                              controller: provider.cityController,
                              hintText: 'E.g., Bangalore',
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: 'State',
                              controller: provider.stateController,
                              hintText: 'E.g., Karnataka',
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      CustomTextField(
                        label: 'Pincode',
                        controller: provider.pincodeController,
                        keyboardType: TextInputType.number,
                        hintText: '6-digit pincode',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 6)
                            return 'Enter a valid 6-digit pincode';
                          return null;
                        },
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
