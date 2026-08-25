import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_upload_card.dart';
import '../widgets/primary_button.dart';

class Step4LegalDocumentsScreen extends StatefulWidget {
  const Step4LegalDocumentsScreen({super.key});

  @override
  State<Step4LegalDocumentsScreen> createState() =>
      _Step4LegalDocumentsScreenState();
}

class _Step4LegalDocumentsScreenState extends State<Step4LegalDocumentsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    final provider = context.read<OnboardingProvider>();
    if (_formKey.currentState!.validate()) {
      if (provider.fssaiImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload FSSAI Certificate')),
        );
        return;
      }
      if (provider.panImage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please upload PAN Card')));
        return;
      }

      provider.saveDraft();
      context.push('/onboarding/step5');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 4),
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
                        'These details help us maintain a trusted marketplace 🛡️',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'FSSAI Number',
                        controller: provider.fssaiNumberController,
                        hintText: '14-digit FSSAI Number',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 14)
                            return 'FSSAI Number must be 14 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          text: 'FSSAI Certificate',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ImageUploadCard(
                        title: 'Upload FSSAI Certificate',
                        subtitle: 'Clear photo of the original document',
                        imageFile: provider.fssaiImage,
                        onTap: () => provider.pickImage('fssai'),
                      ),
                      const SizedBox(height: 32),

                      CustomTextField(
                        label: 'PAN Number',
                        controller: provider.panNumberController,
                        hintText: '10-character PAN Number',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 10) return 'Invalid PAN length';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          text: 'PAN Card',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ImageUploadCard(
                        title: 'Upload PAN Card',
                        subtitle: 'Clear photo of your PAN card',
                        imageFile: provider.panImage,
                        onTap: () => provider.pickImage('pan'),
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
